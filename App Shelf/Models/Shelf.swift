import Foundation
import SwiftData

@Model
final class Shelf {
    var name: String
    var position: Int
    var isDefault: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \MediaItem.shelf)
    var items: [MediaItem]

    init(name: String, position: Int, isDefault: Bool = false) {
        self.name = name
        self.position = position
        self.isDefault = isDefault
        self.createdAt = .now
        self.items = []
    }
}

extension Shelf {
    static let finishedShelfName = "Finished"

    static let defaultShelves: [(name: String, position: Int)] = [
        ("Currently Playing", 0),
        ("Watching", 1),
        ("Backlog", 2),
        ("Finished", 3),
        ("Dropped", 4)
    ]

    var sortedItems: [MediaItem] {
        items.sorted(by: Shelf.itemSort)
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
