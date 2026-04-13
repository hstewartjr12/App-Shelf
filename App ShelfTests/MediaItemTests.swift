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

        let shelf1 = Shelf(name: "Playing", position: 0)
        let shelf2 = Shelf(name: "Finished", position: 1)
        context.insert(shelf1)
        context.insert(shelf2)

        let item = MediaItem(title: "Celeste", shelf: shelf1)
        context.insert(item)
        try context.save()

        item.shelf = shelf2
        try context.save()

        #expect(item.shelf?.name == "Finished")
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
}
