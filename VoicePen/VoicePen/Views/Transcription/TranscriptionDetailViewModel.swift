import SwiftUI
import SwiftData
import AVFoundation

@Observable
final class TranscriptionDetailViewModel {
    var isPlaying = false
    var isEditing = false
    var playbackPosition: TimeInterval = 0
    var totalDuration: TimeInterval = 0
    var exportFormat: ExportFormat = .txt
    var showExportSheet = false
    var showShareSheet = false

    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?

    func setupPlayback(for recording: Recording) {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsDir
            .appendingPathComponent("Recordings", isDirectory: true)
            .appendingPathComponent(recording.audioFileName)

        audioPlayer = try? AVAudioPlayer(contentsOf: audioURL)
        audioPlayer?.prepareToPlay()
        totalDuration = recording.duration
    }

    func togglePlayback() {
        if isPlaying {
            audioPlayer?.pause()
            isPlaying = false
            stopPlaybackTimer()
        } else {
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback, mode: .default)
            try? session.setActive(true)
            audioPlayer?.play()
            isPlaying = true
            startPlaybackTimer()
        }
    }

    func seekTo(time: TimeInterval) {
        audioPlayer?.currentTime = time
        playbackPosition = time
    }

    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        playbackPosition = 0
        stopPlaybackTimer()
    }

    func copyTranscript(_ recording: Recording) {
        UIPasteboard.general.string = recording.totalText
    }

    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.playbackPosition = self.audioPlayer?.currentTime ?? 0
            if self.audioPlayer?.isPlaying == false {
                self.isPlaying = false
                self.stopPlaybackTimer()
            }
        }
    }

    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    deinit {
        stopPlaybackTimer()
    }
}
