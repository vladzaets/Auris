import Foundation

struct TranscriptionLog {
    static func save(text: String, model: String, duration: TimeInterval? = nil) {
        AppConstants.ensureDataDir()

        var entry: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "text": text,
            "model": model,
        ]

        if let duration {
            entry["duration"] = Double(round(duration * 100)) / 100
        }

        guard let data = try? JSONSerialization.data(
            withJSONObject: entry, options: [.withoutEscapingSlashes])
        else { return }

        var newData = data
        newData.append(Data("\n".utf8))

        if FileManager.default.fileExists(atPath: AppConstants.transcriptionsFile.path) {
            if let handle = try? FileHandle(forWritingTo: AppConstants.transcriptionsFile) {
                handle.seekToEndOfFile()
                handle.write(newData)
                handle.closeFile()
            }
        } else {
            try? newData.write(to: AppConstants.transcriptionsFile, options: .atomic)
        }

        pruneIfEnabled()
    }

    static func load() -> [[String: Any]] {
        guard let content = try? String(contentsOf: AppConstants.transcriptionsFile, encoding: .utf8)
        else { return [] }

        var entries: [[String: Any]] = []
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            if let data = trimmed.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            {
                entries.append(obj)
            }
        }
        return entries
    }

    static func saveAll(_ entries: [[String: Any]]) {
        let lines = entries.compactMap { entry -> String? in
            guard let data = try? JSONSerialization.data(
                withJSONObject: entry, options: [.withoutEscapingSlashes])
            else { return nil }
            return String(data: data, encoding: .utf8)
        }
        let content = lines.joined(separator: "\n") + "\n"
        try? content.write(to: AppConstants.transcriptionsFile, atomically: true, encoding: .utf8)
    }

    static func delete(at index: Int) {
        var entries = load()
        guard index >= 0, index < entries.count else { return }
        entries.remove(at: index)
        saveAll(entries)
    }

    static func clearAll() {
        try? Data().write(to: AppConstants.transcriptionsFile, options: .atomic)
    }

    private static func pruneIfEnabled() {
        let days = Settings.shared.historyRetentionDays
        guard days > 0 else { return }

        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let iso = ISO8601DateFormatter()

        let entries = load()
        let kept = entries.filter { entry in
            guard let ts = entry["timestamp"] as? String,
                  let date = iso.date(from: ts)
            else { return true }
            return date >= cutoff
        }

        if kept.count < entries.count {
            saveAll(kept)
        }
    }
}
