import Foundation
import SwiftData

@Model
final class Recording {
    var id: UUID = UUID()
    var title: String = ""
    var createdAt: Date = Date()
    var duration: TimeInterval = 0
    var audioFileName: String = ""
    var language: String = "en"
    var modelUsed: String = "openai_whisper-large-v3-turbo"
    var isPinned: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \TranscriptSegment.recording)
    var segments: [TranscriptSegment]? = []

    var displayTitle: String {
        if title.isEmpty {
            return createdAt.formatted(date: .abbreviated, time: .shortened)
        }
        return title
    }

    var previewText: String {
        (segments ?? []).sorted(by: { $0.startTime < $1.startTime }).first?.text ?? ""
    }

    var totalText: String {
        (segments ?? []).sorted(by: { $0.startTime < $1.startTime }).map(\.text).joined(separator: " ")
    }

    init(
        id: UUID = UUID(),
        title: String = "",
        createdAt: Date = Date(),
        duration: TimeInterval = 0,
        audioFileName: String = "",
        language: String = "en",
        modelUsed: String = "openai_whisper-large-v3-turbo",
        isPinned: Bool = false,
        segments: [TranscriptSegment]? = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.duration = duration
        self.audioFileName = audioFileName
        self.language = language
        self.modelUsed = modelUsed
        self.isPinned = isPinned
        self.segments = segments
    }
}
