import SwiftUI

struct PrivacyBadge: View {
    var compact: Bool = false

    var body: some View {
        if compact {
            HStack(spacing: 3) {
                Image(systemName: "lock.shield.fill")
                Text("Offline")
            }
            .font(.caption2)
            .foregroundStyle(.green)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.green.opacity(0.1))
            .clipShape(Capsule())
        } else {
            HStack(spacing: 4) {
                Image(systemName: "lock.shield.fill")
                Text("100% Offline")
            }
            .font(.caption)
            .foregroundStyle(.green)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.green.opacity(0.1))
            .clipShape(Capsule())
        }
    }
}
