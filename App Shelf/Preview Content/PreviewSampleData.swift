import Foundation
import SwiftData

@MainActor
enum PreviewSampleData {
    static var container: ModelContainer = {
        let schema = Schema([MediaItem.self, Shelf.self, MoodTag.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        // Seed shelves
        let shelves = Shelf.defaultShelves.map { name, position in
            let s = Shelf(name: name, position: position, isDefault: true)
            context.insert(s)
            return s
        }

        // Seed mood tags
        for label in MoodTag.defaults {
            context.insert(MoodTag(label: label))
        }

        // Seed items
        let sampleItems: [(String, MediaType, Int)] = [
            ("Elden Ring", .game, 0),
            ("Hollow Knight", .game, 1),
            ("Severance", .show, 0),
            ("The Bear", .show, 1),
            ("Dune: Part Two", .movie, 0),
            ("The Name of the Wind", .book, 0),
        ]

        for (title, type, pos) in sampleItems {
            let item = MediaItem(
                title: title,
                mediaType: type,
                shelf: shelves[pos < 2 ? 0 : (pos < 4 ? 1 : 2)],
                positionInShelf: pos
            )
            context.insert(item)
        }

        try? context.save()
        return container
    }()
}
