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
    static let defaultShelves: [(name: String, position: Int)] = [
        ("Currently Playing", 0),
        ("Watching", 1),
        ("Backlog", 2),
        ("Finished", 3),
        ("Dropped", 4)
    ]

    var sortedItems: [MediaItem] {
        items.sorted { $0.positionInShelf < $1.positionInShelf }
    }
}
