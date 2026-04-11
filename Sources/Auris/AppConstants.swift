import Foundation

enum AppConstants {
    static let dataDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".auris")
    static let settingsFile = dataDir.appendingPathComponent("settings.json")
    static let correctionsFile = dataDir.appendingPathComponent("corrections.txt")
    static let promptTermsFile = dataDir.appendingPathComponent("prompt_terms.txt")
    static let transcriptionsFile = dataDir.appendingPathComponent("transcriptions.jsonl")

    nonisolated static func ensureDataDir() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: dataDir.path) {
            try? fm.createDirectory(at: dataDir, withIntermediateDirectories: true)
        }
    }
}
