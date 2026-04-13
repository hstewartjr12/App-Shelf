import Testing
import SwiftData
@testable import App_Shelf

@Suite("MoodTag")
struct MoodTagTests {

    // MARK: - Static defaults

    @Test("defaults has exactly 8 entries")
    func defaultsCount() {
        #expect(MoodTag.defaults.count == 8)
    }

    @Test("all default labels are non-empty")
    func defaultLabelsNonEmpty() {
        for label in MoodTag.defaults {
            #expect(!label.isEmpty)
        }
    }

    @Test("all default labels are unique")
    func defaultLabelsUnique() {
        #expect(Set(MoodTag.defaults).count == MoodTag.defaults.count)
    }

    @Test("expected default labels are present")
    func expectedLabels() {
        let expected: Set<String> = ["cozy", "intense", "mid", "masterpiece", "chill", "emotional", "funny", "dark"]
        #expect(Set(MoodTag.defaults) == expected)
    }

    // MARK: - Init

    @Test("init sets label and empty items")
    func initProperties() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let tag = MoodTag(label: "cozy")
        context.insert(tag)

        #expect(tag.label == "cozy")
        #expect(tag.items.isEmpty)
    }

    // MARK: - Relationships

    @Test("MoodTag can be associated with multiple items")
    func moodTagOnMultipleItems() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let tag = MoodTag(label: "cozy")
        context.insert(tag)

        let item1 = MediaItem(title: "Stardew Valley")
        let item2 = MediaItem(title: "Animal Crossing")
        context.insert(item1)
        context.insert(item2)

        item1.moodTags.append(tag)
        item2.moodTags.append(tag)
        try context.save()

        #expect(item1.moodTags.contains(where: { $0.label == "cozy" }))
        #expect(item2.moodTags.contains(where: { $0.label == "cozy" }))
    }

    @Test("Item can have multiple MoodTags")
    func multipleMoodTagsOnItem() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let tag1 = MoodTag(label: "cozy")
        let tag2 = MoodTag(label: "funny")
        context.insert(tag1)
        context.insert(tag2)

        let item = MediaItem(title: "Parks and Rec")
        context.insert(item)
        item.moodTags = [tag1, tag2]
        try context.save()

        #expect(item.moodTags.count == 2)
    }

    // MARK: - Persistence

    @Test("Tags persist after save and fetch")
    func persistenceRoundTrip() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let tag = MoodTag(label: "masterpiece")
        context.insert(tag)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<MoodTag>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.label == "masterpiece")
    }

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Shelf.self, MediaItem.self, MoodTag.self, configurations: config)
    }
}
