import Foundation

enum Autostart {
    private static let label = "com.auris.app"

    private static var plistPath: URL {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
        return dir.appendingPathComponent("\(label).plist")
    }

    static var isEnabled: Bool {
        FileManager.default.fileExists(atPath: plistPath.path)
    }

    static func enable() {
        let dir = plistPath.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let binary: String
        if let exe = Bundle.main.executablePath {
            binary = exe
        } else {
            binary = "/usr/local/bin/auris"
        }

        let plist: [String: Any] = [
            "Label": label,
            "RunAtLoad": true,
            "KeepAlive": false,
            "ProgramArguments": [binary],
        ]

        let data = try? PropertyListSerialization.data(
            fromPropertyList: plist, format: .xml, options: 0)
        try? data?.write(to: plistPath)
    }

    static func disable() {
        if isEnabled {
            try? FileManager.default.removeItem(at: plistPath)
        }
    }
}
