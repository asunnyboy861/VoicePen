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
        var result = text
        result = result.replacingOccurrences(of: ". ", with: ".\n")
        result = result.replacingOccurrences(of: "? ", with: "?\n")
        result = result.replacingOccurrences(of: "! ", with: "!\n")
        return result
    }

    static func capitalizeFirstLetters(_ text: String) -> String {
        var lines = text.components(separatedBy: "\n")
        for i in 0..<lines.count {
            if let firstChar = lines[i].first {
                if firstChar.isLetter {
                    lines[i] = String(firstChar.uppercased()) + lines[i].dropFirst()
                }
            }
        }
        return lines.joined(separator: "\n")
    }
}
