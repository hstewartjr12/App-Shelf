import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        TabView {
            ShelfListView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical.fill")
                }
            StatsView()
                .tabItem {
                    Label("Review", systemImage: "chart.bar.fill")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(ShelfStyle.sageForeground)
        .onAppear {
            DataSeeder.seedIfNeeded(context: context)
            DemoLibrary.seedIfRequested(context: context)
        }
    }
}
