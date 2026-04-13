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
    }

    @Test("seed inserts exactly 8 mood tags")
    func seedInsertsMoodTags() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        DataSeeder.seed(context: context)

        let tags = try context.fetch(FetchDescriptor<MoodTag>())
        #expect(tags.count == 8)
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

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Shelf.self, MediaItem.self, MoodTag.self, configurations: config)
    }
}
