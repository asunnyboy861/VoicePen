import Foundation
import SwiftData

@Model
final class TranscriptSegment {
    @Attribute(.unique) var id: UUID
    var text: String
    var startTime: TimeInterval
    var endTime: TimeInterval
    var confidence: Double

    var recording: Recording?

    var timestampString: String {
        let minutes = Int(startTime) / 60
        let seconds = Int(startTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    init(
        id: UUID = UUID(),
        text: String = "",
        startTime: TimeInterval = 0,
        endTime: TimeInterval = 0,
        confidence: Double = 1.0,
        recording: Recording? = nil
    ) {
        self.id = id
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
        self.confidence = confidence
        self.recording = recording
    }
}
