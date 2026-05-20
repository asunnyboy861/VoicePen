import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()

    private let githubUser = "asunnyboy861"
    private let appName = "VoicePen"

    var body: some View {
        Form {
            transcriptionSection
            storageSection
            privacySection
            supportSection
            legalSection
            aboutSection
        }
        .navigationTitle("Settings")
    }

    private var transcriptionSection: some View {
        Section("Transcription") {
            Picker("Model", selection: $viewModel.selectedModel) {
                ForEach(viewModel.availableModels, id: \.self) { model in
                    HStack {
                        Text(viewModel.modelDisplayName(model))
                        Spacer()
                        Text(viewModel.modelSize(model))
                            .foregroundStyle(.secondary)
                    }
                    .tag(model)
                }
            }

            Toggle("Auto-Stop on Silence", isOn: $viewModel.vadAutoStop)
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
        Section("Privacy") {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(.green)
                Text("100% Offline")
                Spacer()
                Text("Zero Data Collection")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Toggle("iCloud Sync", isOn: $viewModel.iCloudSyncEnabled)
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
