import SwiftUI
import SwiftData

private enum AppShelfMacSection: String, CaseIterable, Hashable, Identifiable {
    case shelf
    case stats

    var id: Self { self }

    var title: String {
        switch self {
        case .shelf:
            return "Shelf"
        case .stats:
            return "Stats"
        }
    }

    var systemImage: String {
        switch self {
        case .shelf:
            return "books.vertical.fill"
        case .stats:
            return "chart.bar.fill"
        }
    }
}

struct AppShelfMacRootView: View {
    @Environment(\.modelContext) private var context
    @State private var selection: AppShelfMacSection? = .shelf

    var body: some View {
        NavigationSplitView {
            List(AppShelfMacSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationTitle("App Shelf")
            .toolbar {
                ToolbarItem {
                    SettingsLink {
                        Label("Open Settings", systemImage: "gearshape")
                    }
                }
            }
        } detail: {
            detailView(for: selection ?? .shelf)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            DataSeeder.seedIfNeeded(context: context)
        }
    }

    @ViewBuilder
    private func detailView(for section: AppShelfMacSection) -> some View {
        switch section {
        case .shelf:
            ShelfListView()
        case .stats:
            StatsView()
        }
    }
}
