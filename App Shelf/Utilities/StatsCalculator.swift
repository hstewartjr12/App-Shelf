import Foundation
import SwiftData

struct TagCount {
    let tag: MoodTag
    let count: Int
}

struct TypeCount {
    let type: MediaType
    let count: Int
}

struct StatsCalculator {
    let items: [MediaItem]
    let tags: [MoodTag]
    let calendar: Calendar

    init(items: [MediaItem], tags: [MoodTag], calendar: Calendar = .current) {
        self.items = items
        self.tags = tags
        self.calendar = calendar
    }

    func itemsFinished(in year: Int) -> [MediaItem] {
        items.filter { item in
            guard let date = item.finishedDate else { return false }
            return calendar.component(.year, from: date) == year
        }
    }

    func finishedCount(in year: Int) -> Int {
        itemsFinished(in: year).count
    }

    func finishedCount(inMonth reference: Date) -> Int {
        items.filter { item in
            guard let date = item.finishedDate else { return false }
            return calendar.isDate(date, equalTo: reference, toGranularity: .month)
        }.count
    }

    func startedCount(in year: Int) -> Int {
        items.filter { item in
            guard let date = item.startedDate else { return false }
            return calendar.component(.year, from: date) == year
        }.count
    }

    func avgShelfTime(year: Int) -> String {
        let finished = itemsFinished(in: year).filter { $0.startedDate != nil }
        guard !finished.isEmpty else { return "—" }
        let durations = finished.compactMap { item -> Double? in
            guard let start = item.startedDate, let end = item.finishedDate else { return nil }
            return end.timeIntervalSince(start)
        }
        guard !durations.isEmpty else { return "—" }
        let avgSeconds = durations.reduce(0, +) / Double(durations.count)
        let days = Int(avgSeconds / 86400)
        if days < 1 { return "< 1 day" }
        if days == 1 { return "1 day" }
        if days < 30 { return "\(days) days" }
        let months = days / 30
        return "\(months) mo"
    }

    func tagCountsSorted(year: Int) -> [TagCount] {
        let finished = itemsFinished(in: year)
        return tags.compactMap { tag in
            let count = finished.filter { item in
                item.moodTags.contains(where: { $0.persistentModelID == tag.persistentModelID })
            }.count
            return count > 0 ? TagCount(tag: tag, count: count) : nil
        }
        .sorted { $0.count > $1.count }
    }

    func typeCounts(year: Int) -> [TypeCount] {
        let finished = itemsFinished(in: year)
        return MediaType.allCases.compactMap { type in
            let count = finished.filter { $0.mediaType == type }.count
            return count > 0 ? TypeCount(type: type, count: count) : nil
        }
        .sorted { $0.count > $1.count }
    }

    func barWidth(count: Int, max: Int) -> CGFloat {
        guard max > 0 else { return 0 }
        return CGFloat(count) / CGFloat(max) * 80
    }
}
