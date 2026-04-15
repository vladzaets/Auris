import AppKit
import Foundation
import os.log

private let logger = Logger(subsystem: "com.vladz.auris", category: "UpdateChecker")

struct RemoteRelease: Sendable {
    let tagName: String
    let htmlURL: String
    let body: String
}

struct Version: Comparable, Sendable {
    let major: Int
    let minor: Int
    let patch: Int

    init(_ string: String) {
        let cleaned = string.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
        let parts = cleaned.split(separator: ".", omittingEmptySubsequences: false).compactMap { Int($0) }
        major = parts.count > 0 ? parts[0] : 0
        minor = parts.count > 1 ? parts[1] : 0
        patch = parts.count > 2 ? parts[2] : 0
    }

    static func < (lhs: Version, rhs: Version) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }

    var displayString: String { "\(major).\(minor).\(patch)" }
}

@MainActor
final class UpdateChecker {
    private static let repo = "vladzaets/auris"
    private static let apiURL = "https://api.github.com/repos/\(repo)/releases/latest"

    static var currentVersion: Version {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        return Version(v)
    }

    static func check(forced: Bool = false) {
        guard Settings.shared.checkForUpdatesEnabled else { return }

        if !forced {
            if let last = Settings.shared.lastUpdateCheck,
               Date().timeIntervalSince(last) < 86400 { return }

            if let skipped = Settings.shared.skippedVersion {
                let skippedV = Version(skipped)
                let latest = currentVersion
                if skippedV > latest || skippedV == latest { return }
            }
        }

        Task {
            guard let release = await fetchLatestRelease() else { return }
            Settings.shared.lastUpdateCheck = Date()

            let remote = Version(release.tagName)
            let local = currentVersion

            if remote > local {
                if !forced, let skipped = Settings.shared.skippedVersion, Version(skipped) == remote { return }
                UpdateAvailableWindow.shared.show(release: release, currentVersion: local)
            } else if forced {
                showUpToDate()
            }
        }
    }

    private static func fetchLatestRelease() async -> RemoteRelease? {
        guard let url = URL(string: apiURL) else { return nil }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                logger.warning("GitHub API returned non-200 status")
                return nil
            }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let tagName = json?["tag_name"] as? String,
                  let htmlURL = json?["html_url"] as? String else { return nil }
            let body = json?["body"] as? String ?? ""
            return RemoteRelease(tagName: tagName, htmlURL: htmlURL, body: body)
        } catch {
            logger.warning("Update check failed: \(error.localizedDescription)")
            return nil
        }
    }

    private static func showUpToDate() {
        let alert = NSAlert()
        alert.messageText = "You're Up to Date"
        alert.informativeText = "Auris \(currentVersion.displayString) is the latest version."
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .informational
        alert.runModal()
    }
}
