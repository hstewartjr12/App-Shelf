import Foundation
import SwiftData

@Model
final class Shelf {
    var name: String = ""
    var position: Int = 0
    var isDefault: Bool = false
    var createdAt: Date = Date.now
    var seedKey: String?

    @Relationship(deleteRule: .cascade, originalName: "items", inverse: \MediaItem.shelf)
    var storedItems: [MediaItem]? = []

    var items: [MediaItem] {
        get { storedItems ?? [] }
        set { storedItems = newValue }
    }

    init(name: String, position: Int, isDefault: Bool = false, seedKey: String? = nil) {
        self.name = name
        self.position = position
        self.isDefault = isDefault
        self.createdAt = .now
        self.seedKey = seedKey
        self.storedItems = []
    }
}

extension Shelf {
    struct BuiltInDefinition: Equatable {
        let seedKey: String
        let name: String
        let position: Int
    }

    static let finishedShelfName = "Finished"

    static let builtInDefinitions: [BuiltInDefinition] = [
        .init(seedKey: "shelf.currently-playing", name: "Currently Playing", position: 0),
        .init(seedKey: "shelf.watching", name: "Watching", position: 1),
        .init(seedKey: "shelf.backlog", name: "Backlog", position: 2),
        .init(seedKey: "shelf.finished", name: "Finished", position: 3),
        .init(seedKey: "shelf.dropped", name: "Dropped", position: 4)
    ]

    static let defaultShelves: [(name: String, position: Int)] = [
        ("Currently Playing", 0),
        ("Watching", 1),
        ("Backlog", 2),
        ("Finished", 3),
        ("Dropped", 4)
    ]

    static func builtInDefinition(forSeedKey seedKey: String) -> BuiltInDefinition? {
        builtInDefinitions.first(where: { $0.seedKey == seedKey })
    }

    static func builtInDefinition(matchingLegacyName name: String) -> BuiltInDefinition? {
        builtInDefinitions.first(where: { $0.name == name })
    }

    var sortedItems: [MediaItem] {
        items.sorted(by: Shelf.itemSort)
    }

    var isFinishedShelf: Bool {
        seedKey == "shelf.finished" || name == Self.finishedShelfName
    }

    var isBacklogShelf: Bool {
        seedKey == "shelf.backlog" || name == "Backlog"
    }

    var systemImage: String {
        switch seedKey ?? Self.builtInDefinition(matchingLegacyName: name)?.seedKey {
        case "shelf.currently-playing": return "gamecontroller"
        case "shelf.watching": return "play.rectangle"
        case "shelf.backlog": return "bookmark"
        case "shelf.finished": return "checkmark.seal"
        case "shelf.dropped": return "pause.circle"
        default: return "books.vertical"
        }
    }

    var nextItemPosition: Int {
        (items.map(\.positionInShelf).max() ?? -1) + 1
    }

    func normalizeItemPositions(removing removedItem: MediaItem? = nil) {
        let removedIdentifier = removedItem?.persistentModelID
        let orderedItems = items
            .filter { item in
                guard let removedIdentifier else { return true }
                return item.persistentModelID != removedIdentifier
            }
            .sorted(by: Shelf.itemSort)

        for (index, item) in orderedItems.enumerated() {
            item.positionInShelf = index
        }
    }

    private static func itemSort(_ lhs: MediaItem, _ rhs: MediaItem) -> Bool {
        if lhs.positionInShelf != rhs.positionInShelf {
            return lhs.positionInShelf < rhs.positionInShelf
        }

        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt < rhs.createdAt
        }

        return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
    }
}
