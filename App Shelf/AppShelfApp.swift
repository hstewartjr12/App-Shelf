import SwiftUI
import SwiftData
import WidgetKit

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

struct RootTabView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        TabView {
            ShelfListView()
                .tabItem {
                    Label("Shelf", systemImage: "books.vertical.fill")
                }
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .onAppear {
            DataSeeder.seedIfNeeded(context: context)
        }
    }
}
