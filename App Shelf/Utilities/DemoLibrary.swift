import Foundation
import SwiftData

/// Opt-in, in-memory sample library for previews and portfolio screenshots.
@MainActor
enum DemoLibrary {
    static func seedIfRequested(context: ModelContext) {
        guard AppShelfContainer.isDemoLibrary,
              (try? context.fetchCount(FetchDescriptor<MediaItem>())) == 0 else { return }
        let shelves = (try? context.fetch(FetchDescriptor<Shelf>())) ?? []
        let tags = (try? context.fetch(FetchDescriptor<MoodTag>())) ?? []
        let samples: [(String, String, MediaType, String, Int, Int, Int?)] = [
            ("Project Hail Mary", "Andy Weir", .book, "shelf.currently-playing", 240, 496, nil),
            ("Hades II", "Supergiant Games", .game, "shelf.currently-playing", 36, 60, nil),
            ("Severance", "Dan Erickson", .show, "shelf.watching", 4, 9, nil),
            ("Blue Train", "John Coltrane", .music, "shelf.currently-playing", 0, 0, nil),
            ("The Wild Robot", "Chris Sanders", .movie, "shelf.finished", 0, 0, 5),
            ("A Short Hike", "Adam Robinson-Yu", .game, "shelf.finished", 4, 4, 5),
            ("Piranesi", "Susanna Clarke", .book, "shelf.finished", 272, 272, 5),
            ("Past Lives", "Celine Song", .movie, "shelf.finished", 0, 0, 4),
            ("In Rainbows", "Radiohead", .music, "shelf.finished", 10, 10, 5),
            ("The Creative Act", "Rick Rubin", .book, "shelf.backlog", 0, 432, nil),
            ("Hollow Knight", "Team Cherry", .game, "shelf.backlog", 0, 0, nil),
            ("The Bear", "Christopher Storer", .show, "shelf.backlog", 0, 10, nil),
            ("Dune: Part Two", "Denis Villeneuve", .movie, "shelf.backlog", 0, 0, nil),
            ("Nurture", "Porter Robinson", .music, "shelf.backlog", 0, 14, nil)
        ]
        for (index, sample) in samples.enumerated() {
            guard let shelf = shelves.first(where: { $0.seedKey == sample.3 }) else { continue }
            let item = MediaItem(title: sample.0, mediaType: sample.2, shelf: shelf, positionInShelf: shelf.nextItemPosition)
            item.creator = sample.1; item.progressCurrent = sample.4; item.progressTotal = sample.5; item.rating = sample.6
            item.createdAt = .now.addingTimeInterval(Double(-index) * 3600)
            item.isFavorite = [0, 4, 6, 8].contains(index)
            item.notes = index == 0 ? "The kind of book that makes you stay up for one more chapter. Left off at the first contact scene." : ""
            item.moodTags = tags.filter { tag in
                switch index {
                case 0, 4, 6: return ["emotional", "masterpiece"].contains(tag.label)
                case 1, 2, 12: return ["intense", "dark"].contains(tag.label)
                case 3, 5, 8, 13: return ["cozy", "chill"].contains(tag.label)
                default: return false
                }
            }
            if shelf.isBacklogShelf { item.startedDate = nil }
            else if shelf.isFinishedShelf {
                let year = Calendar.current.component(.year, from: .now)
                item.finishedDate = Calendar.current.date(from: DateComponents(year: year, month: [1, 3, 5, 7, 9][index - 4], day: 14))
                item.startedDate = item.finishedDate?.addingTimeInterval(-86400 * Double(index + 1))
            }
            context.insert(item)
        }
        try? context.save()
    }
}
