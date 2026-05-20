import SwiftUI
import SwiftData

struct RecordingListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recording.createdAt, order: .reverse)
    private var recordings: [Recording]

    @State private var searchText = ""
    @State private var showRecording = false
    @State private var selectedRecording: Recording?

    var filteredRecordings: [Recording] {
        if searchText.isEmpty {
            return recordings
        }
        return recordings.filter { recording in
            recording.title.localizedCaseInsensitiveContains(searchText) ||
            recording.totalText.localizedCaseInsensitiveContains(searchText)
        }
    }

    var groupedRecordings: [(String, [Recording])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: today)!)

        var groups: [(String, [Recording])] = []

        let pinned = filteredRecordings.filter(\.isPinned)
        if !pinned.isEmpty {
            groups.append(("Pinned", pinned))
        }

        let todayRecordings = filteredRecordings.filter { calendar.isDate($0.createdAt, inSameDayAs: today) && !$0.isPinned }
        if !todayRecordings.isEmpty {
            groups.append(("Today", todayRecordings))
        }

        let yesterdayRecordings = filteredRecordings.filter { calendar.isDate($0.createdAt, inSameDayAs: yesterday) && !$0.isPinned }
        if !yesterdayRecordings.isEmpty {
            groups.append(("Yesterday", yesterdayRecordings))
        }

        let olderRecordings = filteredRecordings.filter { $0.createdAt < yesterday && !$0.isPinned }
        if !olderRecordings.isEmpty {
            groups.append(("Earlier", olderRecordings))
        }

        return groups
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedRecordings, id: \.0) { groupName, items in
                    Section(groupName) {
                        ForEach(items) { recording in
                            NavigationLink(destination: TranscriptionDetailView(recording: recording)) {
                                RecordingRowView(recording: recording)
                            }
                            .swipeActions(edge: .leading) {
                                Button(action: { togglePin(recording) }) {
                                    Label(recording.isPinned ? "Unpin" : "Pin", systemImage: recording.isPinned ? "pin.slash" : "pin")
                                }
                                .tint(.orange)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteRecording(recording)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search transcripts")
            .navigationTitle("VoicePen")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .overlay {
                if recordings.isEmpty {
                    ContentUnavailableView(
                        "No Recordings Yet",
                        systemImage: "mic.badge.plus",
                        description: Text("Tap the record button to create your first transcription.")
                    )
                }
            }
        }
    }

    private func togglePin(_ recording: Recording) {
        recording.isPinned.toggle()
        try? modelContext.save()
    }

    private func deleteRecording(_ recording: Recording) {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsDir
            .appendingPathComponent("Recordings", isDirectory: true)
            .appendingPathComponent(recording.audioFileName)
        try? FileManager.default.removeItem(at: audioURL)
        modelContext.delete(recording)
        try? modelContext.save()
    }
}

struct RecordingRowView: View {
    let recording: Recording

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(recording.displayTitle)
                    .font(.headline)
                    .lineLimit(1)
                if recording.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                Spacer()
                PrivacyBadge(compact: true)
            }

            Text(recording.previewText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Label(formatDuration(recording.duration), systemImage: "timer")
                Spacer()
                Label(recording.createdAt.formatted(.dateTime.hour().minute()), systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    RecordingListView()
        .modelContainer(for: [Recording.self, TranscriptSegment.self])
}
