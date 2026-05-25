import SwiftUI
import SwiftData

@main
struct VoicePenApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    static var sharedModelContainer: ModelContainer = {
        let schema = Schema([Recording.self, TranscriptSegment.self])
        let iCloudSyncEnabled = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
        let config: ModelConfiguration
        if iCloudSyncEnabled {
            config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.com.zzoutuo.VoicePen")
            )
        } else {
            config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
        }
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("ModelContainer creation failed: \(error). Trying local-only fallback.")
            do {
                return try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema)])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView(onComplete: {
                    hasCompletedOnboarding = true
                })
            }
        }
        .modelContainer(VoicePenApp.sharedModelContainer)
    }
}

struct MainTabView: View {
    @State private var selectedTab = 1
    @State private var navigationRecording: Recording?

    var body: some View {
        TabView(selection: $selectedTab) {
            RecordingListView(navigationRecording: $navigationRecording)
                .tabItem {
                    Label("Recordings", systemImage: "list.bullet")
                }
                .tag(0)

            RecordingView(selectedTab: $selectedTab, navigationRecording: $navigationRecording)
                .tabItem {
                    Label("Record", systemImage: "mic")
                }
                .tag(1)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(2)
        }
        .onChange(of: navigationRecording) { _, newValue in
            if newValue != nil {
                selectedTab = 0
            }
        }
    }
}
