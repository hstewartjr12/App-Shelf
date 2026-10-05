import Testing
import SwiftData
import Foundation
@testable import App_Shelf

@Suite("Library workflows")
@MainActor
struct LibraryWorkflowTests {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(for: Shelf.self, MediaItem.self, MoodTag.self,
                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    @Test("Searching combines creator, tags and notes; filters and sorting compose")
    func combinedQuery() throws {
        let container = try makeContainer(); let context = container.mainContext
        let shelf = Shelf(name: "Reading", position: 0); context.insert(shelf)
        let tag = MoodTag(label: "cozy"); context.insert(tag)
        let book = MediaItem(title: "The Night Circus", mediaType: .book, shelf: shelf)
        book.creator = "Erin Morgenstern"; book.moodTags = [tag]; book.notes = "Recommended by a friend"; book.isFavorite = true; book.rating = 5
        let game = MediaItem(title: "A Short Hike", mediaType: .game, shelf: shelf)
        game.moodTags = [tag]; game.rating = 4
        context.insert(book); context.insert(game); try context.save()
        let query = LibraryQuery(search: "morgenstern cozy friend", mediaType: .book, shelf: shelf,
                                 favoritesOnly: true, sort: .rating)
        #expect(query.results(in: [book, game]).map(\.title) == ["The Night Circus"])
        #expect(LibraryQuery(search: "missing").results(in: [book, game]).isEmpty)
        #expect(LibraryQuery(sort: .rating).results(in: [game, book]).first?.libraryID == book.libraryID)
    }

    @Test("Draft edits leave stored data unchanged until Save and persist when applied")
    func draftIsolation() throws {
        let container = try makeContainer(); let context = container.mainContext
        let shelf = Shelf(name: "Reading", position: 0); context.insert(shelf)
        let item = MediaItem(title: "Original", mediaType: .book, shelf: shelf)
        item.notes = "Keep this note"; context.insert(item); try context.save()
        var draft = MediaItemDraft(item: item)
        draft.title = "  Edited  "; draft.notes = "New note"; draft.current = 20; draft.total = 100
        draft.favorite = true; draft.tags.insert("thoughtful")
        #expect(item.title == "Original")
        #expect(item.notes == "Keep this note")
        #expect(item.progressCurrent == 0)
        #expect(try context.fetch(FetchDescriptor<MoodTag>()).isEmpty)
        draft.apply(to: item, context: context, existingTags: [])
        try context.save()
        let fresh = ModelContext(container)
        let reloaded = try #require(try fresh.fetch(FetchDescriptor<MediaItem>()).first)
        #expect(reloaded.title == "Edited")
        #expect(reloaded.notes == "New note")
        #expect(reloaded.progressFraction == 0.2)
        #expect(reloaded.isFavorite)
        #expect(reloaded.moodTags.map(\.label) == ["thoughtful"])
    }

    @Test("Draft rejects blank titles, negative/excess progress and inverted dates")
    func invalidDraft() throws {
        let container = try makeContainer(); let context = container.mainContext
        let item = MediaItem(title: "Book"); context.insert(item)
        var draft = MediaItemDraft(item: item)
        draft.title = " \n "; #expect(draft.validation != nil)
        draft.title = "Book"; draft.current = -1; #expect(draft.validation != nil)
        draft.current = 20; draft.total = 10; #expect(draft.validation != nil)
        draft.current = 1; draft.started = .now; draft.finished = .now.addingTimeInterval(-86400)
        #expect(draft.validation != nil)
        draft.finished = .now.addingTimeInterval(86400); #expect(draft.validation == nil)
    }

    @Test("Backup round trip preserves metadata, cover, tags, positions and is repeatable")
    func archiveRoundTrip() throws {
        let source = try makeContainer(); let context = source.mainContext
        let shelf = Shelf(name: "Reading", position: 0); let emptyShelf = Shelf(name: "Later", position: 1)
        context.insert(shelf); context.insert(emptyShelf)
        let tag = MoodTag(label: "cozy"); context.insert(tag)
        let first = MediaItem(title: "First", mediaType: .book, shelf: shelf, positionInShelf: 0)
        let second = MediaItem(title: "Second", mediaType: .show, shelf: shelf, positionInShelf: 1)
        first.creator = "An author"; first.notes = "A note"; first.rating = 4; first.isFavorite = true
        first.progressCurrent = 50; first.progressTotal = 200; first.progressUnit = "pages"
        first.coverImageData = Data([1, 2, 3]); first.moodTags = [tag]
        context.insert(first); context.insert(second); try context.save()
        let archive = try LibraryArchive.decode(LibraryArchive(shelves: [shelf, emptyShelf], tags: [tag], items: [second, first]).encoded())
        let destination = try makeContainer(); let restoredContext = destination.mainContext
        let report = try archive.merge(into: restoredContext)
        #expect(report.added == 2); #expect(report.shelvesAdded == 2)
        let restored = try #require(try restoredContext.fetch(FetchDescriptor<MediaItem>()).first(where: { $0.libraryID == first.libraryID }))
        #expect(restored.creator == "An author"); #expect(restored.notes == "A note")
        #expect(restored.rating == 4); #expect(restored.isFavorite)
        #expect(restored.progressCurrent == 50); #expect(restored.progressTotal == 200)
        #expect(restored.coverImageData == Data([1, 2, 3])); #expect(restored.moodTags.map(\.label) == ["cozy"])
        #expect(restored.shelf?.sortedItems.map(\.title) == ["First", "Second"])
        restored.notes = "Local edit"; try restoredContext.save()
        let repeatReport = try archive.merge(into: restoredContext)
        #expect(repeatReport.added == 0); #expect(repeatReport.skipped == 2)
        #expect(restored.notes == "Local edit")
        #expect(try restoredContext.fetch(FetchDescriptor<MediaItem>()).count == 2)
        #expect(try restoredContext.fetch(FetchDescriptor<Shelf>()).contains(where: { $0.name == "Later" && $0.items.isEmpty }))
    }

    @Test("Invalid shelf references and future archive versions are rejected before mutation")
    func invalidArchive() throws {
        let container = try makeContainer(); let context = container.mainContext
        let item = MediaItem(title: "Book"); context.insert(item); try context.save()
        let backup = LibraryArchive(shelves: [], tags: [], items: [item])
        var json = try #require(JSONSerialization.jsonObject(with: backup.encoded()) as? [String: Any])
        var items = try #require(json["items"] as? [[String: Any]])
        items[0]["shelfIndex"] = 9; json["items"] = items
        #expect(throws: LibraryArchive.ArchiveError.self) { try LibraryArchive.decode(JSONSerialization.data(withJSONObject: json)) }
        var future = backup; future.version = 2
        #expect(throws: LibraryArchive.ArchiveError.self) { try future.merge(into: context) }
        #expect(try context.fetch(FetchDescriptor<MediaItem>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<Shelf>()).isEmpty)
    }

    @Test("Renaming Finished keeps completion semantics and fills progress")
    func renamedFinishedShelf() throws {
        let container = try makeContainer(); let context = container.mainContext
        let active = Shelf(name: "Reading", position: 0)
        let completed = Shelf(name: "Read and loved", position: 1, isDefault: true, seedKey: "shelf.finished")
        context.insert(active); context.insert(completed)
        let item = MediaItem(title: "Book", shelf: active)
        item.progressCurrent = 5; item.progressTotal = 10; context.insert(item); try context.save()
        #expect(item.move(to: completed)); #expect(item.finishedDate != nil); #expect(item.progressCurrent == 10)
        #expect(item.move(to: active)); #expect(item.finishedDate == nil)
    }

    @Test("Missing or duplicate migrated IDs are backfilled once without changing title data")
    func identifierReconciliation() throws {
        let container = try makeContainer(); let context = container.mainContext
        let first = MediaItem(title: "First"); let second = MediaItem(title: "Second"); let missing = MediaItem(title: "Missing")
        let shared = UUID(); first.libraryID = shared; second.libraryID = shared; missing.storedLibraryID = nil
        first.createdAt = Date(timeIntervalSince1970: 1); second.createdAt = Date(timeIntervalSince1970: 2)
        context.insert(first); context.insert(second); context.insert(missing); try context.save()
        #expect(MediaItem.reconcileLibraryIdentifiers(context: context))
        try context.save()
        #expect(first.libraryID == shared)
        #expect(Set([first.libraryID, second.libraryID, missing.libraryID]).count == 3)
        #expect(!MediaItem.reconcileLibraryIdentifiers(context: context))
        #expect(first.title == "First" && second.title == "Second" && missing.title == "Missing")
    }
}
