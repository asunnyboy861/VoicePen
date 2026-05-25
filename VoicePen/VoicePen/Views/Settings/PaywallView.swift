import SwiftUI
import StoreKit

struct PaywallView: View {
    @State private var purchaseManager = PurchaseManager.shared
    @State private var usageTracker = UsageTracker.shared
    @State private var selectedPlan: PlanType = .yearly
    @State private var isPurchasing = false
    @Environment(\.dismiss) private var dismiss

    enum PlanType: String, CaseIterable {
        case monthly
        case yearly
        case lifetime
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                usageSection
                planSelector
                featureComparison
                purchaseButton
                restoreLink
                termsNote
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .navigationTitle("Upgrade to Pro")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)

            Text("VoicePen Pro")
                .font(.largeTitle)
                .bold()

            Text("Unlimited voice transcription, forever offline.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var usageSection: some View {
        VStack(spacing: 8) {
            Text("Free usage this month")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                ForEach(0..<usageTracker.freeLimit, id: \.self) { index in
                    Image(systemName: index < usageTracker.usageCountThisMonth ? "mic.fill" : "mic")
                        .font(.caption)
                        .foregroundStyle(index < usageTracker.usageCountThisMonth ? Color.accentColor : .secondary)
                }
            }

            Text("\(usageTracker.remainingFreeUses) of \(usageTracker.freeLimit) remaining")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var planSelector: some View {
        VStack(spacing: 10) {
            planCard(.monthly, title: "Monthly", price: purchaseManager.monthlyProduct?.displayPrice ?? "$1.99", subtitle: nil, badge: nil)
            planCard(.yearly, title: "Yearly", price: purchaseManager.yearlyProduct?.displayPrice ?? "$9.99", subtitle: "Only $0.83/mo", badge: "Best Value")
            planCard(.lifetime, title: "Lifetime", price: purchaseManager.lifetimeProduct?.displayPrice ?? "$19.99", subtitle: "One-time purchase", badge: nil)
        }
    }

    private func planCard(_ plan: PlanType, title: String, price: String, subtitle: String?, badge: String?) -> some View {
        Button(action: { selectedPlan = plan }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.headline)
                        if let badge {
                            Text(badge)
                                .font(.caption2)
                                .bold()
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(price)
                    .font(.title3)
                    .bold()
            }
            .padding()
            .background(selectedPlan == plan ? Color.accentColor.opacity(0.1) : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedPlan == plan ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var featureComparison: some View {
        VStack(alignment: .leading, spacing: 8) {
            featureRow(icon: "infinity", text: "Unlimited recordings")
            featureRow(icon: "lock.shield.fill", text: "100% offline & private")
            featureRow(icon: "doc.text", text: "All export formats (TXT, MD, SRT)")
            featureRow(icon: "icloud", text: "iCloud sync across devices")
        }
        .padding()
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
        }
    }

    private var purchaseButton: some View {
        Button(action: purchase) {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                }
                Text(isPurchasing ? "Processing..." : "Subscribe")
                    .bold()
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isPurchasing)
    }

    private var restoreLink: some View {
        Button("Restore Purchases") {
            Task {
                await purchaseManager.restorePurchases()
                if purchaseManager.isPro {
                    dismiss()
                }
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private var termsNote: some View {
        Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period. Manage subscriptions in Settings > Apple ID > Subscriptions.")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
    }

    private func purchase() {
        guard !isPurchasing else { return }
        isPurchasing = true
        Task {
            let product: Product?
            switch selectedPlan {
            case .monthly: product = purchaseManager.monthlyProduct
            case .yearly: product = purchaseManager.yearlyProduct
            case .lifetime: product = purchaseManager.lifetimeProduct
            }
            if let product {
                let success = await purchaseManager.purchase(product)
                if success {
                    dismiss()
                }
            }
            isPurchasing = false
        }
    }
}

#Preview {
    NavigationStack {
        PaywallView()
    }
}
