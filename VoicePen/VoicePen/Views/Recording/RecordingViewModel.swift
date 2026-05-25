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
    var completedRecording: Recording?
    var showPaywall = false

    private let audioRecorder = AudioRecorderService()
    private let transcriptionEngine = TranscriptionEngine.shared
    private let usageTracker = UsageTracker.shared
    private let purchaseManager = PurchaseManager.shared
    private var currentRecordingURL: URL?
    private var currentRecording: Recording?
    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func startRecording() {
        if !purchaseManager.isPro && usageTracker.isLimitReached {
            showPaywall = true
            return
        }

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

        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self, self.isRecording else {
                timer.invalidate()
                return
            }
            self.duration = self.audioRecorder.currentDuration
        }
        timer.tolerance = 0.02
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

        guard let modelContext else {
            errorMessage = "Data storage not ready. Please try again."
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
        modelContext.insert(recording)
        usageTracker.incrementUsage()

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
                await MainActor.run {
                    errorMessage = "Downloading AI model for first-time use. This may take a few minutes..."
                }
                try await transcriptionEngine.loadModel()
                await MainActor.run {
                    errorMessage = nil
                }
            }

            let segments = try await transcriptionEngine.transcribeFile(at: audioURL)

            await MainActor.run {
                for segment in segments {
                    let processed = PostProcessor.processSegment(segment)
                    processed.recording = recording
                    recording.segments?.append(processed)
                    if recording.segments == nil {
                        recording.segments = [processed]
                    }
                }
                isTranscribing = false
                transcriptionProgress = 1.0
                completedRecording = recording
                try? modelContext?.save()
            }
        } catch {
            await MainActor.run {
                isTranscribing = false
                if !transcriptionEngine.isModelLoaded {
                    errorMessage = "Model download failed. Please check your internet connection and try again in Settings."
                } else {
                    errorMessage = "Transcription failed: \(error.localizedDescription)"
                }
            }
        }
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
