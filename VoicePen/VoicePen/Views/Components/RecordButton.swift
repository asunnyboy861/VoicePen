import SwiftUI

struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void

    @State private var pulseAnimation = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if isRecording {
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 88, height: 88)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)

                    Circle()
                        .fill(Color.red)
                        .frame(width: 72, height: 72)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                } else {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 72, height: 72)

                    Image(systemName: "mic.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
        }
        .accessibilityLabel(isRecording ? "Stop Recording" : "Start Recording")
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
}
