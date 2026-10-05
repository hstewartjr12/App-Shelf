import SwiftUI
import SwiftData

@main
struct AppShelfMacApp: App {
    let container: ModelContainer

    @MainActor
    init() {
        AppShelfLaunchPreparation.prepareForSyncIfNeeded(platform: .macOS)
        #if DEBUG
        AppShelfContainer.initializeCloudKitSchemaIfRequested(platform: .macOS)
        #endif
        container = AppShelfContainer.create()
    }

    var body: some Scene {
        WindowGroup {
            AppShelfMacRootView()
                .modelContainer(container)
                .frame(minWidth: 960, minHeight: 680)
        }
        .defaultSize(width: 1180, height: 780)

        Settings {
            SettingsView()
                .modelContainer(container)
                .frame(minWidth: 500, minHeight: 420)
        }
    }
}
