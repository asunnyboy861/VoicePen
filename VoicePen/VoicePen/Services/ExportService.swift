import Foundation
import UniformTypeIdentifiers

enum ExportFormat: String, CaseIterable {
    case txt = "Plain Text"
    case markdown = "Markdown"
    case srt = "SRT Subtitles"

    var fileExtension: String {
        switch self {
        case .txt: return "txt"
        case .markdown: return "md"
        case .srt: return "srt"
        }
    }

    var utType: UTType {
        switch self {
        case .txt: return .plainText
        case .markdown: return UTType(filenameExtension: "md") ?? .plainText
        case .srt: return UTType(filenameExtension: "srt") ?? .plainText
        }
    }
}

struct ExportService {
    static func export(recording: Recording, format: ExportFormat) -> Data? {
        let sortedSegments = recording.segments.sorted { $0.startTime < $1.startTime }

        switch format {
        case .txt:
            return exportAsPlainText(segments: sortedSegments)
        case .markdown:
            return exportAsMarkdown(recording: recording, segments: sortedSegments)
        case .srt:
            return exportAsSRT(segments: sortedSegments)
        }
    }

    static func fileName(for recording: Recording, format: ExportFormat) -> String {
        let baseName = recording.title.isEmpty
            ? recording.createdAt.formatted(.dateTime.year().month().day())
            : recording.title
        let sanitized = baseName.replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        return "\(sanitized).\(format.fileExtension)"
    }

    private static func exportAsPlainText(segments: [TranscriptSegment]) -> Data? {
        let text = segments.map(\.text).joined(separator: "\n\n")
        return text.data(using: .utf8)
    }

    private static func exportAsMarkdown(recording: Recording, segments: [TranscriptSegment]) -> Data? {
        var markdown = "# \(recording.displayTitle)\n\n"
        markdown += "**Date**: \(recording.createdAt.formatted(date: .long, time: .shortened))\n"
        markdown += "**Duration**: \(formatDuration(recording.duration))\n"
        markdown += "**Language**: \(recording.language.uppercased())\n\n"
        markdown += "---\n\n"

        for segment in segments {
            markdown += "**\(segment.timestampString)** — \(segment.text)\n\n"
        }

        return markdown.data(using: .utf8)
    }

    private static func exportAsSRT(segments: [TranscriptSegment]) -> Data? {
        var srt = ""

        for (index, segment) in segments.enumerated() {
            srt += "\(index + 1)\n"
            srt += "\(formatSRTTime(segment.startTime)) --> \(formatSRTTime(segment.endTime))\n"
            srt += "\(segment.text)\n\n"
        }

        return srt.data(using: .utf8)
    }

    private static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    private static func formatSRTTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%02d:%02d:%02d,%03d", hours, minutes, seconds, milliseconds)
    }
}
