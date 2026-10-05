import Testing
import SwiftData
import Foundation
@testable import App_Shelf

@Suite("DataSeeder")
@MainActor
struct DataSeederTests {

    @Test("seed inserts exactly 5 shelves")
    func seedInsertsShelves() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        DataSeeder.seed(context: context)

        let shelves = try context.fetch(FetchDescriptor<Shelf>())
        #expect(shelves.count == 5)
        #expect(Set(shelves.compactMap(\.seedKey)) == Set(Shelf.builtInDefinitions.map(\.seedKey)))
    }

    @Test("seed inserts exactly 8 mood tags")
    func seedInsertsMoodTags() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        DataSeeder.seed(context: context)

        let tags = try context.fetch(FetchDescriptor<MoodTag>())
        #expect(tags.count == 8)
        #expect(Set(tags.compactMap(\.seedKey)) == Set(MoodTag.builtInDefinitions.map(\.seedKey)))
    }

    @Test("seed inserts shelves with correct names")
    func seedShelfNames() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        DataSeeder.seed(context: context)

        let shelves = try context.fetch(FetchDescriptor<Shelf>(sortBy: [SortDescriptor(\.position)]))
        let names = shelves.map(\.name)
        #expect(names == ["Currently Playing", "Watching", "Backlog", "Finished", "Dropped"])
    }

    @Test("seed inserts shelves with correct positions")
    func seedShelfPositions() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        DataSeeder.seed(context: context)

        let shelves = try context.fetch(FetchDescriptor<Shelf>(sortBy: [SortDescriptor(\.position)]))
        let positions = shelves.map(\.position)
        #expect(positions == [0, 1, 2, 3, 4])
    }

    @Test("seed inserts all default mood tag labels")
    func seedMoodTagLabels() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        DataSeeder.seed(context: context)

        let tags = try context.fetch(FetchDescriptor<MoodTag>())
        let labels = Set(tags.map(\.label))
        let expected = Set(MoodTag.defaults)
        #expect(labels == expected)
    }

    @Test("seed does not affect other containers (isolation)")
    func seedIsolation() async throws {
        let container1 = try makeContainer()
        let container2 = try makeContainer()

        DataSeeder.seed(context: ModelContext(container1))

        let shelves2 = try ModelContext(container2).fetch(FetchDescriptor<Shelf>())
        #expect(shelves2.isEmpty)
    }

    @Test("All seeded shelves are marked isDefault")
    func seededShelvesAreDefault() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        DataSeeder.seed(context: context)

        let shelves = try context.fetch(FetchDescriptor<Shelf>())
        let allDefault = shelves.allSatisfy { $0.isDefault }
        #expect(allDefault)
    }

    @Test("seedRequirements detects an empty store")
    func seedRequirementsEmptyStore() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let requirements = DataSeeder.seedRequirements(context: context)

        #expect(requirements == .init(needsShelves: true, needsMoodTags: true))
    }

    @Test("seedIfNeeded reseeds shelves when defaults say seeded but store is empty")
    func seedIfNeededReseedsEmptyShelves() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let defaults = makeDefaults()
        defaults.set(true, forKey: "AppShelf.hasSeeded")

        DataSeeder.seedIfNeeded(context: context, defaults: defaults)

        let shelves = try context.fetch(FetchDescriptor<Shelf>(sortBy: [SortDescriptor(\.position)]))
        #expect(shelves.map(\.name) == ["Currently Playing", "Watching", "Backlog", "Finished", "Dropped"])
    }

    @Test("seedIfNeeded reseeds mood tags when shelves exist but tags are missing")
    func seedIfNeededReseedsMissingTags() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let defaults = makeDefaults()
        defaults.set(true, forKey: "AppShelf.hasSeeded")

        for (name, position) in Shelf.defaultShelves {
            context.insert(Shelf(name: name, position: position, isDefault: true))
        }
        try context.save()

        DataSeeder.seedIfNeeded(context: context, defaults: defaults)

        let tags = try context.fetch(FetchDescriptor<MoodTag>())
        #expect(Set(tags.map(\.label)) == Set(MoodTag.defaults))
    }

    @Test("seedIfNeeded backfills seed keys on legacy built-ins instead of duplicating")
    func seedIfNeededBackfillsLegacyBuiltIns() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        for (name, position) in Shelf.defaultShelves {
            context.insert(Shelf(name: name, position: position, isDefault: true))
        }
        for label in MoodTag.defaults {
            context.insert(MoodTag(label: label))
        }
        try context.save()

        DataSeeder.seedIfNeeded(context: context)

        let shelves = try context.fetch(FetchDescriptor<Shelf>())
        let tags = try context.fetch(FetchDescriptor<MoodTag>())

        #expect(shelves.count == 5)
        #expect(tags.count == 8)
        #expect(Set(shelves.compactMap(\.seedKey)) == Set(Shelf.builtInDefinitions.map(\.seedKey)))
        #expect(Set(tags.compactMap(\.seedKey)) == Set(MoodTag.builtInDefinitions.map(\.seedKey)))
    }

    @Test("duplicate built-in mood tags are collapsed and relationships are preserved")
    func seedIfNeededCollapsesDuplicateBuiltInTags() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let cozySeeded = MoodTag(label: "cozy", seedKey: "tag.cozy")
        let cozyLegacy = MoodTag(label: "cozy")
        let item = MediaItem(title: "Stardew Valley")
        context.insert(cozySeeded)
        context.insert(cozyLegacy)
        context.insert(item)
        item.moodTags = [cozyLegacy]
        try context.save()

        DataSeeder.seedIfNeeded(context: context)

        let tags = try context.fetch(FetchDescriptor<MoodTag>())
        let cozyTags = tags.filter { $0.label == "cozy" }
        let refreshedItem = try #require(try context.fetch(FetchDescriptor<MediaItem>()).first)

        #expect(cozyTags.count == 1)
        #expect(cozyTags.first?.seedKey == "tag.cozy")
        #expect(refreshedItem.moodTags.count == 1)
        #expect(refreshedItem.moodTags.first?.seedKey == "tag.cozy")
    }

    @Test("duplicate default shelves are collapsed and items are preserved")
    func seedIfNeededCollapsesDuplicateBuiltInShelves() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let canonical = Shelf(name: "Finished", position: 0, isDefault: true, seedKey: "shelf.finished")
        let legacyDuplicate = Shelf(name: "Finished", position: 3, isDefault: true)
        context.insert(canonical)
        context.insert(legacyDuplicate)

        let canonicalItem = MediaItem(title: "First", shelf: canonical, positionInShelf: 0)
        let duplicateItem = MediaItem(title: "Second", shelf: legacyDuplicate, positionInShelf: 0)
        context.insert(canonicalItem)
        context.insert(duplicateItem)
        try context.save()

        DataSeeder.seedIfNeeded(context: context)

        let shelves = try context.fetch(FetchDescriptor<Shelf>())
        let finishedShelves = shelves.filter { $0.seedKey == "shelf.finished" || ($0.name == "Finished" && $0.isDefault) }
        let canonicalShelf = try #require(finishedShelves.first)

        #expect(finishedShelves.count == 1)
        #expect(canonicalShelf.sortedItems.map(\.title) == ["First", "Second"])
        #expect(canonicalShelf.sortedItems.map(\.positionInShelf) == [0, 1])
    }

    @Test("custom shelves matching a built-in name are not merged")
    func seedIfNeededLeavesCustomShelvesAlone() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let customWatching = Shelf(name: "Watching", position: 9, isDefault: false)
        context.insert(customWatching)
        try context.save()

        DataSeeder.seedIfNeeded(context: context)

        let shelves = try context.fetch(FetchDescriptor<Shelf>())
        let watchingShelves = shelves.filter { $0.name == "Watching" }

        #expect(watchingShelves.count == 2)
        #expect(watchingShelves.contains(where: { $0.isDefault == false && $0.seedKey == nil }))
        #expect(watchingShelves.contains(where: { $0.seedKey == "shelf.watching" }))
    }

    @Test("custom tags with their own seed key are not merged into built-ins")
    func seedIfNeededLeavesCustomSeededTagsAlone() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let customCozy = MoodTag(label: "cozy", seedKey: "tag.custom-cozy")
        context.insert(customCozy)
        try context.save()

        DataSeeder.seedIfNeeded(context: context)

        let tags = try context.fetch(FetchDescriptor<MoodTag>())
        let cozyTags = tags.filter { $0.label == "cozy" }

        #expect(cozyTags.count == 2)
        #expect(cozyTags.contains(where: { $0.seedKey == "tag.custom-cozy" }))
        #expect(cozyTags.contains(where: { $0.seedKey == "tag.cozy" }))
    }

    @Test("seedIfNeeded marks the defaults flag after ensuring data")
    func seedIfNeededMarksDefaults() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let defaults = makeDefaults()

        DataSeeder.seedIfNeeded(context: context, defaults: defaults)

        #expect(defaults.bool(forKey: "AppShelf.hasSeeded") == true)
    }

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Shelf.self, MediaItem.self, MoodTag.self, configurations: config)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "DataSeederTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
