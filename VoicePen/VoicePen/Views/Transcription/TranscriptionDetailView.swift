import SwiftUI
import SwiftData

struct TranscriptionDetailView: View {
    @Bindable var recording: Recording
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TranscriptionDetailViewModel()
    @State private var titleEditing = false
    @State private var titleText = ""

    var sortedSegments: [TranscriptSegment] {
        (recording.segments ?? []).sorted { $0.startTime < $1.startTime }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerSection
                playbackSection
                transcriptSection
            }
            .padding()
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(recording.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: { viewModel.copyTranscript(recording) }) {
                    Image(systemName: "doc.on.doc")
                }
                .accessibilityLabel("Copy Transcript")

                Menu {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Button(action: {
                            viewModel.exportFormat = format
                            viewModel.showExportSheet = true
                        }) {
                            Label(format.rawValue, systemImage: format == .txt ? "doc.text" : format == .markdown ? "doc.richtext" : "captions.bubble")
                        }
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Export")

                Button(action: {
                    viewModel.isEditing.toggle()
                }) {
                    Image(systemName: viewModel.isEditing ? "checkmark" : "pencil")
                }
                .accessibilityLabel(viewModel.isEditing ? "Done Editing" : "Edit Transcript")
            }
        }
        .sheet(isPresented: $viewModel.showExportSheet) {
            ExportSheetView(recording: recording, format: viewModel.exportFormat)
        }
        .onAppear {
            viewModel.setupPlayback(for: recording)
            titleText = recording.title
        }
        .onDisappear {
            viewModel.deactivateAudioSession()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                Text(recording.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(.secondary)
                Spacer()
                PrivacyBadge()
            }
            .font(.subheadline)

            if titleEditing {
                TextField("Recording title", text: $titleText)
                    .textFieldStyle(.roundedBorder)
                    .font(.headline)
                    .onSubmit {
                        recording.title = titleText
                        try? modelContext.save()
                        titleEditing = false
                    }
            } else {
                Button(action: {
                    titleText = recording.title
                    titleEditing = true
                }) {
                    HStack(spacing: 4) {
                        Text(recording.displayTitle)
                            .font(.headline)
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack {
                Label(formatDuration(recording.duration), systemImage: "timer")
                Spacer()
                Label(recording.language.uppercased(), systemImage: "globe")
                Spacer()
                Label(recording.modelUsed.replacingOccurrences(of: "openai_whisper-", with: ""), systemImage: "cpu")
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var playbackSection: some View {
        VStack(spacing: 12) {
            if viewModel.totalDuration > 0 {
                ProgressView(value: viewModel.playbackPosition, total: viewModel.totalDuration)
                    .tint(.accentColor)

                HStack {
                    Text(formatDuration(viewModel.playbackPosition))
                    Spacer()
                    Button(action: { viewModel.togglePlayback() }) {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color.accentColor)
                    }
                    .accessibilityLabel(viewModel.isPlaying ? "Pause" : "Play")
                    Spacer()
                    Text(formatDuration(viewModel.totalDuration))
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transcript")
                .font(.headline)

            if sortedSegments.isEmpty {
                ContentUnavailableView(
                    "No Transcript Yet",
                    systemImage: "text.bubble",
                    description: Text("Transcription will appear here after recording.")
                )
            } else {
                ForEach(sortedSegments) { segment in
                    TimestampTextView(
                        segment: segment,
                        isEditing: viewModel.isEditing,
                        onTimestampTap: { viewModel.seekTo(time: segment.startTime) },
                        onTextChange: { newText in
                            segment.text = newText
                            try? modelContext.save()
                        }
                    )
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct ExportSheetView: View {
    let recording: Recording
    let format: ExportFormat
    @Environment(\.dismiss) private var dismiss

    private var exportData: Data {
        ExportService.export(recording: recording, format: format) ?? Data()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: format == .txt ? "doc.text" : format == .markdown ? "doc.richtext" : "captions.bubble")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentColor)

                Text("Export as \(format.rawValue)")
                    .font(.headline)

                Text(ExportService.fileName(for: recording, format: format))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ShareLink(
                    item: exportData,
                    preview: SharePreview(
                        ExportService.fileName(for: recording, format: format),
                        image: Image(systemName: "doc.text")
                    )
                ) {
                    Text("Share")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
