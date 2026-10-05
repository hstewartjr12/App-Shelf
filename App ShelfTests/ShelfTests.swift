import Testing
import SwiftData
@testable import App_Shelf

@Suite("Shelf")
struct ShelfTests {

    // MARK: - Static defaults

    @Test("defaultShelves has 5 entries")
    func defaultShelvesCount() {
        #expect(Shelf.defaultShelves.count == 5)
        #expect(Shelf.builtInDefinitions.count == 5)
    }

    @Test("defaultShelves positions are 0-4")
    func defaultShelvesPositions() {
        let positions = Shelf.defaultShelves.map(\.position)
        #expect(positions == [0, 1, 2, 3, 4])
    }

    @Test("defaultShelves names are correct")
    func defaultShelvesNames() {
        let names = Shelf.defaultShelves.map(\.name)
        #expect(names == ["Currently Playing", "Watching", "Backlog", "Finished", "Dropped"])
    }

    // MARK: - Init

    @Test("init sets properties correctly")
    func initProperties() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let shelf = Shelf(name: "Reading", position: 2, isDefault: true)
        context.insert(shelf)

        #expect(shelf.name == "Reading")
        #expect(shelf.position == 2)
        #expect(shelf.isDefault == true)
        #expect(shelf.seedKey == nil)
        #expect(shelf.items.isEmpty)
    }

    @Test("isDefault defaults to false")
    func isDefaultFalseByDefault() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let shelf = Shelf(name: "Custom", position: 5)
        context.insert(shelf)

        #expect(shelf.isDefault == false)
    }

    // MARK: - sortedItems

    @Test("sortedItems returns items ordered by positionInShelf")
    func sortedItemsOrdering() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let shelf = Shelf(name: "Test", position: 0)
        context.insert(shelf)

        let item1 = MediaItem(title: "C", positionInShelf: 2)
        let item2 = MediaItem(title: "A", positionInShelf: 0)
        let item3 = MediaItem(title: "B", positionInShelf: 1)
        item1.shelf = shelf
        item2.shelf = shelf
        item3.shelf = shelf
        context.insert(item1)
        context.insert(item2)
        context.insert(item3)
        try context.save()

        let sorted = shelf.sortedItems
        #expect(sorted.map(\.title) == ["A", "B", "C"])
    }

    @Test("sortedItems on empty shelf returns empty array")
    func sortedItemsEmpty() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let shelf = Shelf(name: "Empty", position: 0)
        context.insert(shelf)

        #expect(shelf.sortedItems.isEmpty)
    }

    @Test("nextItemPosition appends after gaps")
    func nextItemPositionAfterGap() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let shelf = Shelf(name: "Queued", position: 0)
        context.insert(shelf)

        let item1 = MediaItem(title: "First", shelf: shelf, positionInShelf: 0)
        let item2 = MediaItem(title: "Second", shelf: shelf, positionInShelf: 3)
        context.insert(item1)
        context.insert(item2)
        try context.save()

        #expect(shelf.nextItemPosition == 4)
    }

    @Test("normalizeItemPositions compacts gaps while preserving order")
    func normalizeItemPositions() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let shelf = Shelf(name: "Backlog", position: 0)
        context.insert(shelf)

        let item1 = MediaItem(title: "Alpha", shelf: shelf, positionInShelf: 0)
        let item2 = MediaItem(title: "Bravo", shelf: shelf, positionInShelf: 2)
        let item3 = MediaItem(title: "Charlie", shelf: shelf, positionInShelf: 5)
        context.insert(item1)
        context.insert(item2)
        context.insert(item3)
        try context.save()

        shelf.normalizeItemPositions()

        #expect(shelf.sortedItems.map(\.title) == ["Alpha", "Bravo", "Charlie"])
        #expect(shelf.sortedItems.map(\.positionInShelf) == [0, 1, 2])
    }

    // MARK: - Cascade delete

    @Test("Deleting shelf cascades to items")
    func cascadeDelete() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let shelf = Shelf(name: "Doomed", position: 0)
        context.insert(shelf)
        let item = MediaItem(title: "Orphan", shelf: shelf)
        context.insert(item)
        try context.save()

        context.delete(shelf)
        try context.save()

        let remainingItems = try context.fetch(FetchDescriptor<MediaItem>())
        #expect(remainingItems.isEmpty)
    }

    // MARK: - PersistentIdentifierCoder

    @Test("PersistentIdentifierCoder round-trips shelf identifiers")
    func persistentIdentifierRoundTrip() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let shelf = Shelf(name: "Round Trip", position: 0)
        context.insert(shelf)
        try context.save()

        let encoded = PersistentIdentifierCoder.encode(shelf.persistentModelID)
        let decoded = try #require(PersistentIdentifierCoder.decode(encoded))

        #expect(decoded == shelf.persistentModelID)
    }

    @Test("PersistentIdentifierCoder produces stable encoded strings")
    func persistentIdentifierStableEncoding() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let shelf = Shelf(name: "Stable", position: 0)
        context.insert(shelf)
        try context.save()

        let firstEncoding = PersistentIdentifierCoder.encode(shelf.persistentModelID)
        let secondEncoding = PersistentIdentifierCoder.encode(shelf.persistentModelID)

        #expect(firstEncoding == secondEncoding)
    }

    @Test("encoded shelf ID can be used to find a shelf")
    func encodedShelfLookup() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let shelf = Shelf(name: "Lookup", position: 0)
        let otherShelf = Shelf(name: "Other", position: 1)
        context.insert(shelf)
        context.insert(otherShelf)
        try context.save()

        let encoded = PersistentIdentifierCoder.encode(shelf.persistentModelID)
        let decoded = try #require(PersistentIdentifierCoder.decode(encoded))
        let fetchedShelves = try context.fetch(FetchDescriptor<Shelf>())
        let matchedShelf = fetchedShelves.first(where: { $0.persistentModelID == decoded })

        #expect(matchedShelf?.name == "Lookup")
    }

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Shelf.self, MediaItem.self, MoodTag.self, configurations: config)
    }
}
