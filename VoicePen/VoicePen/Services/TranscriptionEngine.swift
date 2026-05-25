import Foundation
import WhisperKit
import SwiftUI
import CoreML

@Observable
final class TranscriptionEngine {
    var whisperKit: WhisperKit?
    var isModelLoaded = false
    var isLoading = false
    var downloadProgress: Double = 0
    var currentModel: String = "openai_whisper-large-v3-turbo"
    var streamingText: String = ""

    private var currentTranscriptSegments: [TranscriptSegment] = []

    static let shared = TranscriptionEngine()

    private init() {}

    func loadModel(_ model: String = "openai_whisper-large-v3-turbo") async throws {
        isLoading = true
        currentModel = model
        defer { isLoading = false }

        whisperKit = try await WhisperKit(
            model: model,
            computeOptions: ModelComputeOptions(
                audioEncoderCompute: .cpuAndNeuralEngine,
                textDecoderCompute: .cpuAndNeuralEngine
            ),
            verbose: true,
            prewarm: false,
            load: true,
            download: true
        )

        isModelLoaded = true
    }

    func transcribeFile(at url: URL) async throws -> [TranscriptSegment] {
        guard let whisperKit = whisperKit else {
            throw TranscriptionError.modelNotLoaded
        }

        let transcriptionResults = try await whisperKit.transcribe(audioPath: url.path)
        currentTranscriptSegments = []

        for result in transcriptionResults {
            for segment in result.segments {
                let ts = TranscriptSegment(
                    text: segment.text,
                    startTime: TimeInterval(segment.start),
                    endTime: TimeInterval(segment.end),
                    confidence: Double(segment.avgLogprob)
                )
                currentTranscriptSegments.append(ts)
            }
        }

        return currentTranscriptSegments
    }

    func transcribeStream(audioBuffer: [Float]) async throws -> String? {
        guard let whisperKit = whisperKit else {
            throw TranscriptionError.modelNotLoaded
        }

        let transcriptionResults = try await whisperKit.transcribe(audioArray: audioBuffer)

        guard let result = transcriptionResults.first else { return nil }

        DispatchQueue.main.async { [weak self] in
            self?.streamingText = result.text
        }

        return result.text
    }

    func getAvailableModels() -> [String] {
        return [
            "openai_whisper-large-v3-turbo",
            "openai_whisper-large-v3",
            "openai_whisper-medium",
            "openai_whisper-small",
            "openai_whisper-base",
            "openai_whisper-tiny"
        ]
    }

    func modelSize(for model: String) -> String {
        switch model {
        case "openai_whisper-large-v3-turbo": return "~300 MB"
        case "openai_whisper-large-v3": return "~1.5 GB"
        case "openai_whisper-medium": return "~750 MB"
        case "openai_whisper-small": return "~250 MB"
        case "openai_whisper-base": return "~75 MB"
        case "openai_whisper-tiny": return "~40 MB"
        default: return "Unknown"
        }
    }

    func unloadModel() {
        whisperKit = nil
        isModelLoaded = false
    }
}

enum TranscriptionError: LocalizedError {
    case modelNotLoaded
    case transcriptionFailed(String)
    case audioFileNotFound

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded: return "Transcription model is not loaded yet."
        case .transcriptionFailed(let msg): return "Transcription failed: \(msg)"
        case .audioFileNotFound: return "Audio file not found."
        }
    }
}
