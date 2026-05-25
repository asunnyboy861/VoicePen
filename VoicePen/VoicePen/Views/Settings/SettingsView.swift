import SwiftUI
import StoreKit

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var purchaseManager = PurchaseManager.shared
    @State private var usageTracker = UsageTracker.shared
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = false
    @State private var showiCloudRestartAlert = false

    private let githubUser = "asunnyboy861"
    private let appName = "VoicePen"

    var body: some View {
        Form {
            proSection
            transcriptionSection
            storageSection
            privacySection
            supportSection
            legalSection
            aboutSection
        }
        .navigationTitle("Settings")
    }

    private var proSection: some View {
        Section {
            if purchaseManager.isPro {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("VoicePen Pro")
                            .font(.headline)
                        if purchaseManager.isLifetimePurchased {
                            Text("Lifetime — Unlimited recordings")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if let sub = purchaseManager.activeSubscription {
                            Text("\(sub.displayPrice)/period — Unlimited recordings")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text("Active")
                        .font(.caption)
                        .bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "crown")
                            .foregroundStyle(.yellow)
                        Text("Free Plan")
                            .font(.headline)
                    }
                    HStack(spacing: 4) {
                        ForEach(0..<usageTracker.freeLimit, id: \.self) { index in
                            Image(systemName: index < usageTracker.usageCountThisMonth ? "mic.fill" : "mic")
                                .font(.caption2)
                                .foregroundStyle(index < usageTracker.usageCountThisMonth ? Color.accentColor : .secondary)
                        }
                        Text("— \(usageTracker.remainingFreeUses) left this month")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    NavigationLink(destination: PaywallView()) {
                        Text("Upgrade to Pro")
                            .font(.subheadline)
                            .bold()
                    }
                }
            }
        } header: {
            Text("Subscription")
        }
    }

    private var transcriptionSection: some View {
        Section("Transcription") {
            Picker("Model", selection: $viewModel.selectedModel) {
                ForEach(viewModel.availableModels, id: \.self) { model in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.modelDisplayName(model))
                            if !viewModel.isModelDownloaded(model) {
                                Text("Not downloaded — will download on switch")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                        }
                        Spacer()
                        Text(viewModel.modelSize(model))
                            .foregroundStyle(.secondary)
                    }
                    .tag(model)
                }
            }

            if viewModel.isReloadingModel {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        ProgressView()
                        Text("Loading model...")
                            .foregroundStyle(.secondary)
                    }
                    Text("Downloading and initializing the AI model. This may take a few minutes for large models.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var storageSection: some View {
        Section("Storage") {
            HStack {
                Text("Recordings")
                Spacer()
                Text(viewModel.recordingsStorage)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("AI Models")
                Spacer()
                Text(viewModel.modelsStorage)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var privacySection: some View {
        Section("Privacy & Sync") {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(.green)
                Text("100% Offline")
                Spacer()
                Text("Zero Data Collection")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Toggle(isOn: $iCloudSyncEnabled) {
                HStack {
                    Image(systemName: "icloud")
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("iCloud Sync")
                        Text("Sync recordings across devices")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onChange(of: iCloudSyncEnabled) { _, newValue in
                showiCloudRestartAlert = true
            }
            .alert("Restart Required", isPresented: $showiCloudRestartAlert) {
                Button("OK") { }
            } message: {
                Text("iCloud sync has been \(iCloudSyncEnabled ? "enabled" : "disabled"). Please restart the app for changes to take effect.")
            }
        }
    }

    private var supportSection: some View {
        Section("Support") {
            NavigationLink(destination: ContactSupportView()) {
                Label("Contact Support", systemImage: "envelope")
            }

            Link(destination: URL(string: "https://\(githubUser).github.io/\(appName)/support.html")!) {
                Label("Help Center", systemImage: "questionmark.circle")
            }
        }
    }

    private var legalSection: some View {
        Section("Legal") {
            Link("Privacy Policy", destination: URL(string: "https://\(githubUser).github.io/\(appName)/privacy.html")!)
            Link("Support Page", destination: URL(string: "https://\(githubUser).github.io/\(appName)/support.html")!)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Build")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
