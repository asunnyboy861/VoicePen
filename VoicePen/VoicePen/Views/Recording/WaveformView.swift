import SwiftUI

struct WaveformView: View {
    var level: Float
    var isActive: Bool

    private let barCount = 40
    private let minHeight: CGFloat = 3
    private let maxHeight: CGFloat = 50

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(barColor(for: index))
                    .frame(width: 3, height: barHeight(for: index))
                    .animation(.easeOut(duration: 0.05), value: level)
            }
        }
        .frame(height: maxHeight)
    }

    private func barHeight(for index: Int) -> CGFloat {
        guard isActive else { return minHeight }

        let center = Float(barCount) / 2.0
        let distance = abs(Float(index) - center) / center
        let baseHeight = Float(maxHeight) * level * (1.0 - distance * 0.5)
        let noise = Float.random(in: 0.7...1.3)
        return CGFloat(max(Float(minHeight), baseHeight * noise))
    }

    private func barColor(for index: Int) -> Color {
        guard isActive else { return .gray.opacity(0.3) }

        let center = Double(barCount) / 2.0
        let distance = abs(Double(index) - center) / center
        return Color.accentColor.opacity(1.0 - distance * 0.4)
    }
}

#Preview {
    VStack {
        WaveformView(level: 0.5, isActive: true)
        WaveformView(level: 0.0, isActive: false)
    }
    .padding()
}
