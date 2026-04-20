import SwiftUI
import SwiftData

@main
struct AppShelfApp: App {
    let container: ModelContainer

    init() {
        container = AppShelfContainer.create()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .modelContainer(container)
        }
    }
}
