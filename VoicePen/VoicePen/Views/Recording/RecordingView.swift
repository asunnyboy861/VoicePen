import SwiftUI
import SwiftData

struct RecordingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = RecordingViewModel()
    @State private var usageTracker = UsageTracker.shared
    @State private var purchaseManager = PurchaseManager.shared
    @Binding var selectedTab: Int
    @Binding var navigationRecording: Recording?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            if viewModel.isTranscribing {
                transcriptionProgressView
            } else if viewModel.isRecording {
                activeRecordingView
            } else {
                idleRecordingView
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
        .onChange(of: viewModel.completedRecording) { _, newValue in
            if let recording = newValue {
                navigationRecording = recording
                viewModel.completedRecording = nil
            }
        }
        .sheet(isPresented: $viewModel.showPaywall) {
            NavigationStack {
                PaywallView()
            }
        }
    }

    private var idleRecordingView: some View {
        VStack(spacing: 32) {
            Image(systemName: "waveform.circle")
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor)

            if purchaseManager.isPro {
                Label("Pro — Unlimited", systemImage: "crown.fill")
                    .font(.subheadline)
                    .foregroundStyle(.yellow)
            } else {
                usageIndicator
            }

            Text("Tap to Record")
                .font(.title2)
                .foregroundStyle(.secondary)

            Button(action: { viewModel.startRecording() }) {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.red)
            }
            .accessibilityLabel("Start Recording")
        }
    }

    private var usageIndicator: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(0..<usageTracker.freeLimit, id: \.self) { index in
                    Image(systemName: index < usageTracker.usageCountThisMonth ? "mic.fill" : "mic")
                        .font(.caption2)
                        .foregroundStyle(index < usageTracker.usageCountThisMonth ? Color.accentColor : .secondary)
                }
            }
            Text("\(usageTracker.remainingFreeUses) of \(usageTracker.freeLimit) free this month")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var activeRecordingView: some View {
        VStack(spacing: 24) {
            WaveformView(level: viewModel.audioLevel, isActive: viewModel.isRecording && !viewModel.isPaused)

            Text(viewModel.formattedDuration)
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundStyle(.primary)

            if !viewModel.streamingText.isEmpty {
                ScrollView {
                    Text(viewModel.streamingText)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                .frame(maxHeight: 120)
            }

            HStack(spacing: 48) {
                if viewModel.isPaused {
                    Button(action: { viewModel.resumeRecording() }) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.green)
                    }
                    .accessibilityLabel("Resume Recording")
                } else {
                    Button(action: { viewModel.pauseRecording() }) {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.orange)
                    }
                    .accessibilityLabel("Pause Recording")
                }

                Button(action: { viewModel.stopRecording() }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.red)
                }
                .accessibilityLabel("Stop Recording")
            }
        }
    }

    private var transcriptionProgressView: some View {
        VStack(spacing: 16) {
            ProgressView(value: viewModel.transcriptionProgress)
                .progressViewStyle(.circular)
                .scaleEffect(1.5)

            if let error = viewModel.errorMessage, error.contains("Downloading") || error.contains("download failed") {
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("Transcribing...")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("Your audio is being processed on-device")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

#Preview {
    RecordingView(selectedTab: .constant(1), navigationRecording: .constant(nil))
        .modelContainer(for: [Recording.self, TranscriptSegment.self])
}
