import SwiftUI
import SwiftData

@Observable
final class RecordingViewModel {
    var isRecording = false
    var isPaused = false
    var duration: TimeInterval = 0
    var audioLevel: Float = 0.0
    var streamingText = ""
    var isTranscribing = false
    var transcriptionProgress: Double = 0
    var errorMessage: String?

    private let audioRecorder = AudioRecorderService()
    private let transcriptionEngine = TranscriptionEngine.shared
    private var currentRecordingURL: URL?
    private var currentRecording: Recording?
    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func startRecording() {
        guard let url = audioRecorder.startRecording() else {
            errorMessage = "Could not start recording. Please check microphone permissions."
            return
        }
        currentRecordingURL = url
        isRecording = true
        isPaused = false
        duration = 0
        streamingText = ""
        errorMessage = nil

        audioRecorder.onAudioLevelUpdate = { [weak self] level in
            DispatchQueue.main.async {
                self?.audioLevel = level
            }
        }

        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self, self.isRecording else {
                timer.invalidate()
                return
            }
            self.duration = self.audioRecorder.currentDuration
        }
    }

    func pauseRecording() {
        audioRecorder.pauseRecording()
        isPaused = true
    }

    func resumeRecording() {
        audioRecorder.resumeRecording()
        isPaused = false
    }

    func stopRecording() {
        let result = audioRecorder.stopRecording()
        isRecording = false
        isPaused = false
        audioLevel = 0.0

        guard let url = result.url, result.duration > 0 else {
            errorMessage = "Recording failed or was too short."
            return
        }

        let recording = Recording(
            title: "",
            createdAt: Date(),
            duration: result.duration,
            audioFileName: url.lastPathComponent,
            language: "en",
            modelUsed: transcriptionEngine.currentModel
        )
        currentRecording = recording
        modelContext?.insert(recording)

        Task {
            await transcribeRecording(recording, audioURL: url)
        }
    }

    private func transcribeRecording(_ recording: Recording, audioURL: URL) async {
        await MainActor.run {
            isTranscribing = true
            transcriptionProgress = 0
        }

        do {
            if !transcriptionEngine.isModelLoaded {
                try await transcriptionEngine.loadModel()
            }

            let segments = try await transcriptionEngine.transcribeFile(at: audioURL)

            await MainActor.run {
                for segment in segments {
                    let processed = PostProcessor.processSegment(segment)
                    processed.recording = recording
                    recording.segments.append(processed)
                }
                isTranscribing = false
                transcriptionProgress = 1.0
                try? modelContext?.save()
            }
        } catch {
            await MainActor.run {
                isTranscribing = false
                errorMessage = "Transcription failed: \(error.localizedDescription)"
            }
        }
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
