import Testing
import SwiftData
import Foundation
@testable import App_Shelf

@Suite("MediaItem")
struct MediaItemTests {

    // MARK: - Init defaults

    @Test("notes defaults to empty string")
    func notesDefault() throws {
        let item = try makeItem()
        #expect(item.notes == "")
    }

    @Test("rating defaults to nil")
    func ratingDefault() throws {
        let item = try makeItem()
        #expect(item.rating == nil)
    }

    @Test("coverImageData defaults to nil")
    func coverImageDataDefault() throws {
        let item = try makeItem()
        #expect(item.coverImageData == nil)
    }

    @Test("moodTags defaults to empty array")
    func moodTagsDefault() throws {
        let item = try makeItem()
        #expect(item.moodTags.isEmpty)
    }

    @Test("finishedDate defaults to nil")
    func finishedDateDefault() throws {
        let item = try makeItem()
        #expect(item.finishedDate == nil)
    }

    @Test("startedDate is set on init")
    func startedDateSet() throws {
        let before = Date.now
        let item = try makeItem()
        let after = Date.now
        let started = try #require(item.startedDate)
        #expect(started >= before && started <= after)
    }

    @Test("mediaType defaults to .other")
    func mediaTypeDefault() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let item = MediaItem(title: "Test")
        context.insert(item)
        #expect(item.mediaType == .other)
    }

    // MARK: - Custom init values

    @Test("Custom mediaType is stored correctly", arguments: MediaType.allCases)
    func mediaTypeStored(type: MediaType) throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let item = MediaItem(title: "Test", mediaType: type)
        context.insert(item)
        #expect(item.mediaType == type)
    }

    @Test("positionInShelf is stored correctly")
    func positionInShelf() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let item = MediaItem(title: "Test", positionInShelf: 7)
        context.insert(item)
        #expect(item.positionInShelf == 7)
    }

    // MARK: - Shelf relationship

    @Test("Assigning shelf updates relationship")
    func shelfAssignment() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let shelf = Shelf(name: "Backlog", position: 0)
        context.insert(shelf)
        let item = MediaItem(title: "Hades", shelf: shelf)
        context.insert(item)
        try context.save()

        #expect(item.shelf?.name == "Backlog")
        #expect(shelf.items.contains(where: { $0.title == "Hades" }))
    }

    @Test("Item can be moved between shelves")
    func moveBetweenShelves() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let sourceShelf = Shelf(name: "Playing", position: 0)
        let destinationShelf = Shelf(name: "Finished", position: 1)
        context.insert(sourceShelf)
        context.insert(destinationShelf)

        let sourceA = MediaItem(title: "Source A", shelf: sourceShelf, positionInShelf: 0)
        let movingItem = MediaItem(title: "Celeste", shelf: sourceShelf, positionInShelf: 1)
        let sourceB = MediaItem(title: "Source B", shelf: sourceShelf, positionInShelf: 2)
        let destinationA = MediaItem(title: "Destination A", shelf: destinationShelf, positionInShelf: 0)
        let destinationB = MediaItem(title: "Destination B", shelf: destinationShelf, positionInShelf: 2)
        context.insert(sourceA)
        context.insert(movingItem)
        context.insert(sourceB)
        context.insert(destinationA)
        context.insert(destinationB)
        try context.save()

        let moved = movingItem.move(to: destinationShelf)
        try context.save()

        #expect(moved == true)
        #expect(movingItem.shelf?.name == "Finished")
        #expect(sourceShelf.sortedItems.map(\.title) == ["Source A", "Source B"])
        #expect(sourceShelf.sortedItems.map(\.positionInShelf) == [0, 1])
        #expect(destinationShelf.sortedItems.map(\.title) == ["Destination A", "Destination B", "Celeste"])
        #expect(destinationShelf.sortedItems.map(\.positionInShelf) == [0, 1, 2])
    }

    @Test("move(to:) is a no-op when moving to the current shelf")
    func moveToSameShelfNoOp() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let shelf = Shelf(name: "Playing", position: 0)
        context.insert(shelf)

        let item = MediaItem(title: "Celeste", shelf: shelf, positionInShelf: 4)
        item.finishedDate = date(year: 2025, month: 3, day: 14)
        context.insert(item)
        try context.save()

        let moved = item.move(to: shelf)

        #expect(moved == false)
        #expect(item.shelf?.name == "Playing")
        #expect(item.positionInShelf == 4)
        #expect(item.finishedDate == date(year: 2025, month: 3, day: 14))
    }

    @Test("normalizing before delete closes shelf gaps")
    func deleteNormalization() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let shelf = Shelf(name: "Backlog", position: 0)
        context.insert(shelf)

        let first = MediaItem(title: "First", shelf: shelf, positionInShelf: 0)
        let second = MediaItem(title: "Second", shelf: shelf, positionInShelf: 1)
        let third = MediaItem(title: "Third", shelf: shelf, positionInShelf: 2)
        context.insert(first)
        context.insert(second)
        context.insert(third)
        try context.save()

        shelf.normalizeItemPositions(removing: second)
        context.delete(second)
        try context.save()

        #expect(shelf.sortedItems.map(\.title) == ["First", "Third"])
        #expect(shelf.sortedItems.map(\.positionInShelf) == [0, 1])
    }

    // MARK: - Mutation

    @Test("rating can be set and updated")
    func ratingMutation() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let item = MediaItem(title: "Dune")
        context.insert(item)

        item.rating = 5
        #expect(item.rating == 5)

        item.rating = nil
        #expect(item.rating == nil)
    }

    @Test("finishedDate can be set")
    func finishedDateMutation() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let item = MediaItem(title: "Dune")
        context.insert(item)

        let now = Date.now
        item.finishedDate = now
        #expect(item.finishedDate == now)
    }

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Shelf.self, MediaItem.self, MoodTag.self, configurations: config)
    }

    private func makeItem() throws -> MediaItem {
        let container = try makeContainer()
        let context = ModelContext(container)
        let item = MediaItem(title: "Test Item")
        context.insert(item)
        return item
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return Calendar.current.date(from: components)!
    }
}
