import Foundation

struct PostProcessor {
    static func process(_ rawText: String) -> String {
        var text = rawText
        text = fixPunctuationWords(text)
        text = removeFillerWords(text)
        text = filterHallucinations(text)
        text = sentenceSegmentation(text)
        text = capitalizeFirstLetters(text)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func processSegment(_ segment: TranscriptSegment) -> TranscriptSegment {
        let processedText = process(segment.text)
        return TranscriptSegment(
            id: segment.id,
            text: processedText,
            startTime: segment.startTime,
            endTime: segment.endTime,
            confidence: segment.confidence,
            recording: segment.recording
        )
    }

    static func fixPunctuationWords(_ text: String) -> String {
        var result = text
        let replacements: [(String, String)] = [
            (" comma", ","),
            (" period", "."),
            (" question mark", "?"),
            (" exclamation mark", "!"),
            (" exclamation point", "!"),
            (" semicolon", ";"),
            (" colon", ":"),
            (" new line", "\n"),
            (" newline", "\n"),
            (", comma", ","),
            (". period", "."),
            ("  comma", ","),
            ("  period", ".")
        ]
        for (word, punctuation) in replacements {
            result = result.replacingOccurrences(of: word, with: punctuation)
        }
        return result
    }

    static func removeFillerWords(_ text: String) -> String {
        var result = text
        let fillers = ["um", "uh", "hmm", "huh", "ah", "er", "like, ", "you know, ", "嗯", "啊", "呃", "那个"]
        for filler in fillers {
            result = result.replacingOccurrences(of: " \(filler) ", with: " ")
            result = result.replacingOccurrences(of: " \(filler),", with: ",")
            result = result.replacingOccurrences(of: " \(filler).", with: ".")
        }
        return result
    }

    static func filterHallucinations(_ text: String) -> String {
        var result = text
        let hallucinationPatterns = [
            "Thank you for watching",
            "Thanks for watching",
            "Subscribe to my channel",
            "Please like and subscribe",
            "I hope you enjoyed",
            "Thank you for listening"
        ]
        for pattern in hallucinationPatterns {
            result = result.replacingOccurrences(of: pattern, with: "")
        }
        result = result.replacingOccurrences(of: "<\\|[^>]+\\|>", with: "", options: .regularExpression)
        return result
    }

    static func sentenceSegmentation(_ text: String) -> String {
        return text
    }

    static func capitalizeFirstLetters(_ text: String) -> String {
        var result = text
        if let firstChar = result.first, firstChar.isLetter {
            result = String(firstChar.uppercased()) + result.dropFirst()
        }
        let sentenceEnders = [". ", "? ", "! "]
        for ender in sentenceEnders {
            let parts = result.components(separatedBy: ender)
            if parts.count > 1 {
                result = parts.enumerated().map { index, part in
                    if index == 0 { return part }
                    var trimmed = part
                    if let first = trimmed.first, first.isLetter {
                        trimmed = String(first.uppercased()) + trimmed.dropFirst()
                    }
                    return trimmed
                }.joined(separator: ender)
            }
        }
        return result
    }
}
