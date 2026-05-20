import SwiftUI
import SwiftData

@main
struct VoicePenApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Recording.self, TranscriptSegment.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.zzoutuo.VoicePen")
        )
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            return try! ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema)])
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
        .modelContainer(sharedModelContainer)
    }
}

struct MainTabView: View {
    @State private var selectedTab = 1

    var body: some View {
        TabView(selection: $selectedTab) {
            RecordingListView()
                .tabItem {
                    Label("Recordings", systemImage: "list.bullet")
                }
                .tag(0)

            RecordingView()
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
    }
}
