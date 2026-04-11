import Foundation

enum TextCleaner {
    private static let minRepeats = 4

    private static let trailingFillerWords: Set<String> = [
        "of", "the", "a", "an", "and", "or", "but", "in", "to", "for",
        "with", "it's", "its", "is", "was", "that", "this", "very",
        "our", "their", "his", "her",
    ]

    private static let singleWordSkip: Set<String> = [
        "the", "a", "an", "and", "or", "i", "to", "of", "in", "is",
    ]

    private static let fillerRegexes: [NSRegularExpression] = {
        let patterns = [
            "\\byou know,?\\s*",
            "\\bI mean,?\\s*",
            "\\bkind of\\b",
            "\\bsort of\\b",
            "\\bum+\\b(?!-)",
            "(?<!-)\\buh+\\b(?!-)",
            "\\bahh?\\b(?!-)",
            "\\bhmm+\\b",
            "\\berm+\\b",
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0, options: .caseInsensitive) }
    }()

    static func stripHallucinationLoops(_ text: String) -> String {
        guard !text.isEmpty, text.count >= 50 else { return text }

        let words = text.components(separatedBy: " ")
        guard words.count >= minRepeats * 2 else { return text }

        var bestCut: (position: Int, phrase: String, count: Int)?

        for phraseLen in stride(from: min(6, words.count / minRepeats), through: 1, by: -1) {
            var i = 0
            while i <= words.count - phraseLen * minRepeats {
                let phrase = words[i..<(i + phraseLen)].joined(separator: " ").lowercased()

                if phraseLen == 1 && singleWordSkip.contains(phrase.trimmingCharacters(in: .punctuationCharacters)) {
                    i += 1
                    continue
                }

                var count = 1
                var j = i + phraseLen
                while j + phraseLen <= words.count {
                    let segment = words[j..<(j + phraseLen)].joined(separator: " ").lowercased()
                    if segment == phrase {
                        count += 1
                        j += phraseLen
                    } else {
                        break
                    }
                }

                if count >= minRepeats {
                    if bestCut == nil || i < bestCut!.position {
                        bestCut = (i, phrase, count)
                    }
                    break
                }
                i += 1
            }
        }

        guard let cut = bestCut else { return text }

        var clean = Array(words[0..<cut.position])

        while !clean.isEmpty && trailingFillerWords.contains(clean.last!.lowercased().trimmingCharacters(in: .punctuationCharacters)) {
            clean.removeLast()
        }

        var result = clean.joined(separator: " ").trimmingCharacters(in: CharacterSet(charactersIn: " ,;:-"))
        if !result.isEmpty {
            let last = result[result.index(before: result.endIndex)]
            if !".!?\"'".contains(last) {
                result += "."
            }
        }

        return result
    }

    static func removeFillerWords(_ text: String) -> String {
        guard !text.isEmpty else { return text }

        var cleaned = text
        let fullRange = NSRange(location: 0, length: (text as NSString).length)
        for regex in fillerRegexes {
            cleaned = regex.stringByReplacingMatches(
                in: cleaned, options: [], range: NSRange(location: 0, length: (cleaned as NSString).length),
                withTemplate: ""
            )
        }

        let artifactRegexes: [(NSRegularExpression, String)] = [
            (try! NSRegularExpression(pattern: ",\\s*,"), ","),
            (try! NSRegularExpression(pattern: "\\s+"), " "),
            (try! NSRegularExpression(pattern: "\\s+([.,!?;:])"), "$1"),
            (try! NSRegularExpression(pattern: "([.!?])\\s*,"), "$1"),
            (try! NSRegularExpression(pattern: "^\\s*,\\s*"), ""),
            (try! NSRegularExpression(pattern: "([.!?])\\s*,\\s*"), "$1 "),
        ]

        for (regex, template) in artifactRegexes {
            cleaned = regex.stringByReplacingMatches(
                in: cleaned, options: [], range: NSRange(location: 0, length: (cleaned as NSString).length),
                withTemplate: template
            )
        }

        cleaned = cleaned.trimmingCharacters(in: .whitespaces)

        if !cleaned.isEmpty && cleaned.first!.isLowercase {
            cleaned.replaceSubrange(cleaned.startIndex...cleaned.startIndex, with: String(cleaned.first!).uppercased())
        }

        return cleaned
    }
}
