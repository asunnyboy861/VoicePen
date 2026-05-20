import SwiftUI

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var isRequestingPermission = false
    @State private var isDownloadingModel = false
    @State private var downloadProgress: Double = 0
    @State private var permissionGranted = false
    @State private var modelDownloaded = false

    let onComplete: () -> Void

    private let steps = [
        OnboardingStep(
            icon: "waveform.circle",
            title: "Welcome to VoicePen",
            subtitle: "Transform your voice into text, completely offline.",
            description: "No cloud uploads. No subscriptions. Your voice stays on your device."
        ),
        OnboardingStep(
            icon: "mic.fill",
            title: "Microphone Access",
            subtitle: "VoicePen needs your microphone to record audio.",
            description: "Your audio never leaves your device. All processing happens locally."
        ),
        OnboardingStep(
            icon: "brain",
            title: "Download AI Model",
            subtitle: "A small AI model is needed for transcription.",
            description: "This ~300MB model enables on-device speech recognition. Downloaded once, works forever."
        ),
        OnboardingStep(
            icon: "checkmark.circle",
            title: "You're All Set!",
            subtitle: "Start recording and see your words appear as text.",
            description: "Tap the record button anytime to begin."
        )
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: steps[currentStep].icon)
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)
                .symbolEffect(.bounce, value: currentStep)

            VStack(spacing: 8) {
                Text(steps[currentStep].title)
                    .font(.title.bold())

                Text(steps[currentStep].subtitle)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(steps[currentStep].description)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer()

            stepSpecificContent

            HStack(spacing: 12) {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation { currentStep -= 1 }
                    }
                    .foregroundStyle(.secondary)
                }

                Button(action: handleNext) {
                    Text(currentStep == steps.count - 1 ? "Get Started" : "Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isRequestingPermission || isDownloadingModel)
            }
            .padding(.horizontal)
            .padding(.bottom)

            PageControl(numberOfPages: steps.count, currentPage: currentStep)
        }
        .padding()
    }

    @ViewBuilder
    private var stepSpecificContent: some View {
        switch currentStep {
        case 1:
            if permissionGranted {
                Label("Microphone Access Granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if isRequestingPermission {
                ProgressView()
            }
        case 2:
            if modelDownloaded {
                Label("Model Downloaded", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if isDownloadingModel {
                VStack(spacing: 8) {
                    ProgressView(value: downloadProgress)
                    Text("\(Int(downloadProgress * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
        default:
            EmptyView()
        }
    }

    private func handleNext() {
        switch currentStep {
        case 1:
            requestMicrophonePermission()
        case 2:
            downloadModel()
        case 3:
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            onComplete()
        default:
            withAnimation { currentStep += 1 }
        }
    }

    private func requestMicrophonePermission() {
        isRequestingPermission = true
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                self.isRequestingPermission = false
                self.permissionGranted = granted
                if granted {
                    withAnimation { self.currentStep += 1 }
                }
            }
        }
    }

    private func downloadModel() {
        isDownloadingModel = true
        Task {
            do {
                let engine = TranscriptionEngine.shared
                try await engine.loadModel()
                await MainActor.run {
                    self.isDownloadingModel = false
                    self.modelDownloaded = true
                    withAnimation { self.currentStep += 1 }
                }
            } catch {
                await MainActor.run {
                    self.isDownloadingModel = false
                    withAnimation { self.currentStep += 1 }
                }
            }
        }
    }
}

import AVFoundation

struct OnboardingStep {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
}

struct PageControl: View {
    let numberOfPages: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { page in
                Circle()
                    .fill(page == currentPage ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
