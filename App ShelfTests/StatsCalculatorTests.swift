import Testing
import SwiftData
import Foundation
@testable import App_Shelf

@Suite("StatsCalculator")
struct StatsCalculatorTests {

    // MARK: - itemsFinished

    @Test("finishedCount is 0 when no items finished in year")
    func finishedCountEmpty() throws {
        let calc = StatsCalculator(items: [], tags: [])
        #expect(calc.finishedCount(in: 2024) == 0)
    }

    @Test("finishedCount counts only items finished in the given year")
    func finishedCountByYear() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let item2024 = makeFinished(title: "A", year: 2024, context: context)
        let item2025a = makeFinished(title: "B", year: 2025, context: context)
        let item2025b = makeFinished(title: "C", year: 2025, context: context)
        let unfinished = MediaItem(title: "D")
        context.insert(unfinished)
        try context.save()

        let calc = StatsCalculator(items: [item2024, item2025a, item2025b, unfinished], tags: [])
        #expect(calc.finishedCount(in: 2024) == 1)
        #expect(calc.finishedCount(in: 2025) == 2)
        #expect(calc.finishedCount(in: 2023) == 0)
    }

    // MARK: - startedCount

    @Test("startedCount counts items with startedDate in given year")
    func startedCountByYear() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let item1 = MediaItem(title: "X")
        item1.startedDate = date(year: 2025, month: 3, day: 1)
        context.insert(item1)

        let item2 = MediaItem(title: "Y")
        item2.startedDate = date(year: 2024, month: 6, day: 15)
        context.insert(item2)

        let item3 = MediaItem(title: "Z")
        item3.startedDate = nil
        context.insert(item3)
        try context.save()

        let calc = StatsCalculator(items: [item1, item2, item3], tags: [])
        #expect(calc.startedCount(in: 2025) == 1)
        #expect(calc.startedCount(in: 2024) == 1)
        #expect(calc.startedCount(in: 2023) == 0)
    }

    // MARK: - avgShelfTime

    @Test("avgShelfTime returns em-dash when no finished items")
    func avgShelfTimeEmpty() {
        let calc = StatsCalculator(items: [], tags: [])
        #expect(calc.avgShelfTime(year: 2025) == "—")
    }

    @Test("avgShelfTime returns < 1 day for same-day finish")
    func avgShelfTimeSameDay() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let item = MediaItem(title: "Quick Read")
        let start = date(year: 2025, month: 1, day: 1)
        item.startedDate = start
        item.finishedDate = start.addingTimeInterval(3600) // 1 hour
        context.insert(item)
        try context.save()

        let calc = StatsCalculator(items: [item], tags: [])
        #expect(calc.avgShelfTime(year: 2025) == "< 1 day")
    }

    @Test("avgShelfTime returns '1 day' for exactly one day")
    func avgShelfTimeOneDay() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let item = MediaItem(title: "One Day Book")
        item.startedDate = date(year: 2025, month: 1, day: 1)
        item.finishedDate = date(year: 2025, month: 1, day: 2) // 1 day later
        context.insert(item)
        try context.save()

        let calc = StatsCalculator(items: [item], tags: [])
        #expect(calc.avgShelfTime(year: 2025) == "1 day")
    }

    @Test("avgShelfTime returns days string for 2-29 days")
    func avgShelfTimeDays() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let item = MediaItem(title: "Week Read")
        item.startedDate = date(year: 2025, month: 1, day: 1)
        item.finishedDate = date(year: 2025, month: 1, day: 8) // 7 days
        context.insert(item)
        try context.save()

        let calc = StatsCalculator(items: [item], tags: [])
        #expect(calc.avgShelfTime(year: 2025) == "7 days")
    }

    @Test("avgShelfTime returns months string for 30+ days")
    func avgShelfTimeMonths() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let item = MediaItem(title: "Long Game")
        item.startedDate = date(year: 2025, month: 1, day: 1)
        item.finishedDate = date(year: 2025, month: 3, day: 1) // ~59 days = 1 mo
        context.insert(item)
        try context.save()

        let calc = StatsCalculator(items: [item], tags: [])
        let result = calc.avgShelfTime(year: 2025)
        #expect(result.hasSuffix("mo"))
    }

    @Test("avgShelfTime averages multiple items")
    func avgShelfTimeAverages() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        // Item 1: 3 days
        let item1 = MediaItem(title: "A")
        item1.startedDate = date(year: 2025, month: 1, day: 1)
        item1.finishedDate = date(year: 2025, month: 1, day: 4)
        context.insert(item1)

        // Item 2: 7 days
        let item2 = MediaItem(title: "B")
        item2.startedDate = date(year: 2025, month: 2, day: 1)
        item2.finishedDate = date(year: 2025, month: 2, day: 8)
        context.insert(item2)

        try context.save()

        // Average = 5 days
        let calc = StatsCalculator(items: [item1, item2], tags: [])
        #expect(calc.avgShelfTime(year: 2025) == "5 days")
    }

    // MARK: - typeCounts

    @Test("typeCounts returns empty for no finished items")
    func typeCountsEmpty() {
        let calc = StatsCalculator(items: [], tags: [])
        #expect(calc.typeCounts(year: 2025).isEmpty)
    }

    @Test("typeCounts groups finished items by media type")
    func typeCountsGrouping() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let game1 = makeFinished(title: "G1", year: 2025, type: .game, context: context)
        let game2 = makeFinished(title: "G2", year: 2025, type: .game, context: context)
        let book1 = makeFinished(title: "B1", year: 2025, type: .book, context: context)
        try context.save()

        let calc = StatsCalculator(items: [game1, game2, book1], tags: [])
        let counts = calc.typeCounts(year: 2025)

        #expect(counts.first?.type == .game)
        #expect(counts.first?.count == 2)
        #expect(counts.last?.type == .book)
        #expect(counts.last?.count == 1)
    }

    @Test("typeCounts excludes types with zero finished items")
    func typeCountsExcludesZero() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let game = makeFinished(title: "Game", year: 2025, type: .game, context: context)
        try context.save()

        let calc = StatsCalculator(items: [game], tags: [])
        let counts = calc.typeCounts(year: 2025)

        #expect(counts.count == 1)
        #expect(counts.first?.type == .game)
    }

    // MARK: - tagCountsSorted

    @Test("tagCountsSorted returns empty when no finished items")
    func tagCountsEmpty() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let tag = MoodTag(label: "cozy")
        context.insert(tag)

        let calc = StatsCalculator(items: [], tags: [tag])
        #expect(calc.tagCountsSorted(year: 2025).isEmpty)
    }

    @Test("tagCountsSorted counts tags on finished items")
    func tagCountsCounting() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let cozy = MoodTag(label: "cozy")
        let intense = MoodTag(label: "intense")
        context.insert(cozy)
        context.insert(intense)

        let item1 = makeFinished(title: "A", year: 2025, context: context)
        let item2 = makeFinished(title: "B", year: 2025, context: context)
        let item3 = makeFinished(title: "C", year: 2025, context: context)
        item1.moodTags = [cozy]
        item2.moodTags = [cozy, intense]
        item3.moodTags = [intense]
        try context.save()

        let calc = StatsCalculator(items: [item1, item2, item3], tags: [cozy, intense])
        let counts = calc.tagCountsSorted(year: 2025)

        #expect(counts.count == 2)
        #expect(counts[0].tag.label == "cozy")
        #expect(counts[0].count == 2)
        #expect(counts[1].tag.label == "intense")
        #expect(counts[1].count == 2)
    }

    @Test("tagCountsSorted is sorted descending by count")
    func tagCountsSorting() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let rare = MoodTag(label: "rare")
        let common = MoodTag(label: "common")
        context.insert(rare)
        context.insert(common)

        let item1 = makeFinished(title: "A", year: 2025, context: context)
        let item2 = makeFinished(title: "B", year: 2025, context: context)
        let item3 = makeFinished(title: "C", year: 2025, context: context)
        item1.moodTags = [rare]
        item2.moodTags = [common]
        item3.moodTags = [common]
        try context.save()

        let calc = StatsCalculator(items: [item1, item2, item3], tags: [rare, common])
        let counts = calc.tagCountsSorted(year: 2025)

        #expect(counts.first?.tag.label == "common")
        #expect(counts.first?.count == 2)
    }

    // MARK: - finishedCount(inMonth:)

    @Test("finishedCount(inMonth:) counts items finished in matching month")
    func finishedCountInMonth() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let janItem = MediaItem(title: "Jan")
        janItem.finishedDate = date(year: 2025, month: 1, day: 15)
        context.insert(janItem)

        let febItem = MediaItem(title: "Feb")
        febItem.finishedDate = date(year: 2025, month: 2, day: 10)
        context.insert(febItem)
        try context.save()

        let calc = StatsCalculator(items: [janItem, febItem], tags: [])
        #expect(calc.finishedCount(inMonth: date(year: 2025, month: 1, day: 1)) == 1)
        #expect(calc.finishedCount(inMonth: date(year: 2025, month: 2, day: 1)) == 1)
        #expect(calc.finishedCount(inMonth: date(year: 2025, month: 3, day: 1)) == 0)
    }

    // MARK: - barWidth

    @Test("barWidth returns 0 when max is 0")
    func barWidthZeroMax() {
        let calc = StatsCalculator(items: [], tags: [])
        #expect(calc.barWidth(count: 5, max: 0) == 0)
    }

    @Test("barWidth returns 80 when count equals max")
    func barWidthFull() {
        let calc = StatsCalculator(items: [], tags: [])
        #expect(calc.barWidth(count: 10, max: 10) == 80)
    }

    @Test("barWidth returns proportional width")
    func barWidthProportional() {
        let calc = StatsCalculator(items: [], tags: [])
        #expect(calc.barWidth(count: 5, max: 10) == 40)
    }

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Shelf.self, MediaItem.self, MoodTag.self, configurations: config)
    }

    @discardableResult
    private func makeFinished(
        title: String,
        year: Int,
        type: MediaType = .other,
        context: ModelContext
    ) -> MediaItem {
        let item = MediaItem(title: title, mediaType: type)
        item.finishedDate = date(year: year, month: 6, day: 15)
        item.startedDate = date(year: year, month: 1, day: 1)
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
