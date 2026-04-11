import Foundation

final class PostProcessor {
    private var patterns: [(regex: NSRegularExpression, replacement: String)] = []
    private(set) var patternCount = 0

    init(vocabulary: [String: String] = [:], includeUserCorrections: Bool = true) {
        var allVocab: [String: String] = [:]
        allVocab.merge(vocabulary) { _, new in new }

        if includeUserCorrections {
            let user = Self.loadUserCorrections()
            allVocab.merge(user) { _, new in new }
        }

        for (pattern, replacement) in allVocab {
            let wordBoundaried = pattern.hasPrefix("\\b") ? pattern : "\\b" + pattern + "\\b"
            if let regex = try? NSRegularExpression(pattern: wordBoundaried, options: .caseInsensitive) {
                patterns.append((regex, replacement))
            }
        }

        patternCount = patterns.count
    }

    func apply(_ text: String) -> String {
        guard !text.isEmpty, !patterns.isEmpty else { return text }

        var result = text
        for (regex, replacement) in patterns {
            result = regex.stringByReplacingMatches(
                in: result, options: [],
                range: NSRange(location: 0, length: (result as NSString).length),
                withTemplate: replacement
            )
        }
        return result
    }

    static func loadUserCorrections() -> [String: String] {
        let url = AppConstants.correctionsFile
        guard FileManager.default.fileExists(atPath: url.path) else { return [:] }

        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return [:] }

        var corrections: [String: String] = [:]
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

            guard let arrowRange = trimmed.range(of: " -> ") else { continue }

            let wrong = String(trimmed[trimmed.startIndex..<arrowRange.lowerBound])
                .trimmingCharacters(in: .whitespaces)
            let right = String(trimmed[arrowRange.upperBound..<trimmed.endIndex])
                .trimmingCharacters(in: .whitespaces)

            guard !wrong.isEmpty, !right.isEmpty else { continue }

            let escaped = NSRegularExpression.escapedPattern(for: wrong)
            let pattern = "\\b" + escaped + "\\b"
            corrections[pattern] = right
        }

        return corrections
    }

    static func createCorrectionsTemplate() {
        let url = AppConstants.correctionsFile
        guard !FileManager.default.fileExists(atPath: url.path) else { return }

        AppConstants.ensureDataDir()

        let template = """
        # Auris — Custom Corrections
        #
        # Add your own corrections here, one per line.
        # Format:  wrong spelling -> correct spelling
        #
        # Examples:
        # Priresh -> Priyesh
        # post gres -> PostgreSQL
        # john also -> John Allsopp
        #
        # Lines starting with # are comments.
        # Matching is case-insensitive and whole-word.
        # Changes take effect on next transcription.

        """
        try? template.write(to: url, atomically: true, encoding: .utf8)
    }
}
