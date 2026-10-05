import SwiftUI
import SwiftData

@main
struct AppShelfApp: App {
    let container: ModelContainer

    @MainActor
    init() {
        AppShelfLaunchPreparation.prepareForSyncIfNeeded(platform: .iOS)
        #if DEBUG
        AppShelfContainer.initializeCloudKitSchemaIfRequested(platform: .iOS)
        #endif
        container = AppShelfContainer.create()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .modelContainer(container)
        }
    }
}
