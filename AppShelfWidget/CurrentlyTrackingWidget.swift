import WidgetKit
import SwiftUI
import SwiftData

struct WidgetEntry: TimelineEntry {
    let date: Date
    let shelfName: String
    let items: [WidgetMediaItem]
}

struct CurrentlyTrackingProvider: AppIntentTimelineProvider {
    typealias Entry = WidgetEntry
    typealias Intent = SelectShelfIntent

    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: .now, shelfName: "Currently Playing", items: [])
    }

    func snapshot(for configuration: SelectShelfIntent, in context: Context) async -> WidgetEntry {
        await fetchEntry(for: configuration)
    }

    func timeline(for configuration: SelectShelfIntent, in context: Context) async -> Timeline<WidgetEntry> {
        let entry = await fetchEntry(for: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    @MainActor
    private func fetchEntry(for configuration: SelectShelfIntent) async -> WidgetEntry {
        let container = AppShelfContainer.create()
        let context = ModelContext(container)

        do {
            let descriptor = FetchDescriptor<Shelf>(sortBy: [SortDescriptor(\.position)])
            let shelves = try context.fetch(descriptor)

            let targetShelf: Shelf?
            if let entityId = configuration.shelf?.id {
                targetShelf = shelves.first(where: {
                    $0.persistentModelID.hashValue.description == entityId
                }) ?? shelves.first
            } else {
                targetShelf = shelves.first
            }

            guard let shelf = targetShelf else {
                return WidgetEntry(date: .now, shelfName: "My Shelf", items: [])
            }

            let items = shelf.sortedItems.prefix(3).map { item in
                WidgetMediaItem(
                    id: item.persistentModelID.hashValue.description,
                    title: item.title,
                    coverImageData: item.coverImageData,
                    mediaType: item.mediaType
                )
            }

            return WidgetEntry(date: .now, shelfName: shelf.name, items: Array(items))
        } catch {
            return WidgetEntry(date: .now, shelfName: "My Shelf", items: [])
        }
    }
}
