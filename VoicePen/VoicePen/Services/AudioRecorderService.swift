import Foundation
import AVFoundation
import UIKit

@Observable
final class AudioRecorderService: NSObject {
    private var audioRecorder: AVAudioRecorder?
    private var meterTimer: Timer?
    private var startTime: Date?
    private var _isRecording = false
    private var _isPaused = false
    private var accumulatedDuration: TimeInterval = 0

    var isRecording: Bool { _isRecording }
    var isPaused: Bool { _isPaused }
    var currentDuration: TimeInterval {
        guard let start = startTime else { return accumulatedDuration }
        return accumulatedDuration + Date().timeIntervalSince(start)
    }
    var audioLevel: Float = 0.0

    var onRecordingComplete: ((URL, TimeInterval) -> Void)?
    var onAudioLevelUpdate: ((Float) -> Void)?

    private let documentsDirectory: URL = {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingsDir = url.appendingPathComponent("Recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: recordingsDir, withIntermediateDirectories: true)
        return recordingsDir
    }()

    override init() {
        super.init()
    }

    func startRecording() -> URL? {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            return nil
        }

        let fileName = "recording_\(UUID().uuidString).m4a"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            _isRecording = true
            _isPaused = false
            startTime = Date()
            accumulatedDuration = 0
            startMeterTimer()
            return fileURL
        } catch {
            return nil
        }
    }

    func pauseRecording() {
        guard _isRecording, !_isPaused else { return }
        audioRecorder?.pause()
        _isPaused = true
        if let start = startTime {
            accumulatedDuration += Date().timeIntervalSince(start)
        }
        startTime = nil
        stopMeterTimer()
    }

    func resumeRecording() {
        guard _isRecording, _isPaused else { return }
        audioRecorder?.record()
        _isPaused = false
        startTime = Date()
        startMeterTimer()
    }

    func stopRecording() -> (url: URL?, duration: TimeInterval) {
        guard _isRecording else { return (nil, 0) }

        let duration = currentDuration
        let url = audioRecorder?.url

        audioRecorder?.stop()
        _isRecording = false
        _isPaused = false
        stopMeterTimer()

        if let start = startTime {
            accumulatedDuration += Date().timeIntervalSince(start)
        }
        startTime = nil

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)

        if let url = url {
            onRecordingComplete?(url, duration)
        }

        return (url, duration)
    }

    private func startMeterTimer() {
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateMeters()
        }
    }

    private func stopMeterTimer() {
        meterTimer?.invalidate()
        meterTimer = nil
        audioLevel = 0.0
        onAudioLevelUpdate?(0.0)
    }

    private func updateMeters() {
        audioRecorder?.updateMeters()
        let level = audioRecorder?.averagePower(forChannel: 0) ?? -160
        let normalizedLevel = max(0, (level + 160) / 160)
        audioLevel = normalizedLevel
        onAudioLevelUpdate?(normalizedLevel)
    }
}

extension AudioRecorderService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        _isRecording = false
        _isPaused = false
        stopMeterTimer()
    }
}
