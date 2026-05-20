import SwiftUI

struct TimestampTextView: View {
    let segment: TranscriptSegment
    let isEditing: Bool
    let onTimestampTap: () -> Void
    let onTextChange: (String) -> Void

    @State private var editedText: String = ""

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Button(action: onTimestampTap) {
                Text(segment.timestampString)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .accessibilityLabel("Jump to \(segment.timestampString)")

            if isEditing {
                TextField("Edit text", text: $editedText, axis: .vertical)
                    .font(.body)
                    .onChange(of: editedText) { _, newValue in
                        onTextChange(newValue)
                    }
                    .onAppear {
                        editedText = segment.text
                    }
            } else {
                Text(segment.text)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
            }
        }
        .padding(.vertical, 4)
    }
}
