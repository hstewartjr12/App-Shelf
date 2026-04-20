import Testing
import SwiftData
@testable import App_Shelf

@Suite("AddItemAvailability")
@MainActor
struct AddItemAvailabilityTests {

    @Test("canSubmit is false when no shelves exist")
    func canSubmitWithoutShelves() {
        let availability = AddItemAvailability(
            title: "Metaphor",
            selectedShelf: nil,
            shelves: []
        )

        #expect(availability.hasShelves == false)
        #expect(availability.resolvedShelf == nil)
        #expect(availability.canSubmit == false)
    }

    @Test("canSubmit is false for whitespace-only titles")
    func canSubmitRejectsBlankTitles() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let shelf = Shelf(name: "Backlog", position: 0)
        context.insert(shelf)

        let availability = AddItemAvailability(
            title: "   ",
            selectedShelf: shelf,
            shelves: [shelf]
        )

        #expect(availability.trimmedTitle.isEmpty)
        #expect(availability.canSubmit == false)
    }

    @Test("resolvedShelf falls back to the first shelf when none is selected")
    func resolvedShelfFallsBackToFirstShelf() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let firstShelf = Shelf(name: "Playing", position: 0)
        let secondShelf = Shelf(name: "Finished", position: 1)
        context.insert(firstShelf)
        context.insert(secondShelf)

        let availability = AddItemAvailability(
            title: "Dune",
            selectedShelf: nil,
            shelves: [firstShelf, secondShelf]
        )

        #expect(availability.resolvedShelf?.persistentModelID == firstShelf.persistentModelID)
        #expect(availability.canSubmit == true)
    }

    @Test("canSubmit is true for a trimmed title with a selected shelf")
    func canSubmitWithValidInputs() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let shelf = Shelf(name: "Reading", position: 0)
        context.insert(shelf)

        let availability = AddItemAvailability(
            title: "  Project Hail Mary  ",
            selectedShelf: shelf,
            shelves: [shelf]
        )

        #expect(availability.trimmedTitle == "Project Hail Mary")
        #expect(availability.canSubmit == true)
    }

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Shelf.self, MediaItem.self, MoodTag.self, configurations: config)
    }
}
