import SwiftUI
import AVFoundation
import Speech

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var isRequestingPermission = false
    @State private var isDownloadingModel = false
    @State private var downloadProgress: Double = 0
    @State private var permissionGranted = false
    @State private var speechPermissionGranted = false
    @State private var modelDownloaded = false
    @State private var modelDownloadFailed = false

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
            title: "Permissions & AI Model",
            subtitle: "VoicePen needs microphone access and an AI model for transcription.",
            description: "Your audio never leaves your device. The ~300MB model enables on-device speech recognition."
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
                    Text(currentStep == steps.count - 1 ? "Get Started" : (currentStep == 1 && modelDownloadFailed ? "Skip for Now" : "Continue"))
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
            VStack(spacing: 12) {
                if permissionGranted && speechPermissionGranted {
                    Label("All Permissions Granted", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else if isRequestingPermission {
                    ProgressView()
                    Text("Requesting permissions...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: permissionGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(permissionGranted ? .green : .red)
                            Text("Microphone")
                                .font(.caption)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: speechPermissionGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(speechPermissionGranted ? .green : .red)
                            Text("Speech Recognition")
                                .font(.caption)
                        }
                        if !permissionGranted || !speechPermissionGranted {
                            Text("Some permissions were denied. You can enable them later in Settings > Privacy.")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                }

                Divider()

                if modelDownloaded {
                    Label("Model Downloaded", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else if modelDownloadFailed {
                    VStack(spacing: 8) {
                        Label("Download Failed", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("You can download the model later in Settings. Transcription will require the model to be downloaded first.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else if isDownloadingModel {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Downloading AI model... This may take a few minutes.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                }
            }
        default:
            EmptyView()
        }
    }

    private func handleNext() {
        switch currentStep {
        case 0:
            withAnimation { currentStep += 1 }
            requestPermissions()
        case 1:
            if modelDownloaded {
                withAnimation { currentStep += 1 }
            } else if modelDownloadFailed {
                withAnimation { currentStep += 1 }
            } else {
                downloadModel()
            }
        case 2:
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            onComplete()
        default:
            withAnimation { currentStep += 1 }
        }
    }

    private func requestPermissions() {
        isRequestingPermission = true
        let group = DispatchGroup()

        group.enter()
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.permissionGranted = granted
                }
                group.leave()
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.permissionGranted = granted
                }
                group.leave()
            }
        }

        group.enter()
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.speechPermissionGranted = (status == .authorized)
            }
            group.leave()
        }

        group.notify(queue: .main) {
            self.isRequestingPermission = false
        }
    }

    private func downloadModel() {
        isDownloadingModel = true
        modelDownloadFailed = false
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
                    self.modelDownloadFailed = true
                }
            }
        }
    }
}

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
