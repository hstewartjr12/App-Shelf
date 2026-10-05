import Foundation
import SwiftData

struct LibraryArchive: Codable {
    var version = 1
    let exportedAt: Date
    let shelves: [ShelfRecord]
    let tags: [String]
    let items: [ItemRecord]

    struct ShelfRecord: Codable {
        let name: String
        let seedKey: String?
        let position: Int
    }
    struct ItemRecord: Codable {
        let id: UUID
        let title: String
        let creator: String
        let mediaType: MediaType
        let shelfIndex: Int?
        let position: Int
        let createdAt: Date
        let started: Date?
        let finished: Date?
        let rating: Int?
        let notes: String
        let favorite: Bool
        let current: Int
        let total: Int
        let unit: String
        let tags: [String]
        let cover: Data?
    }
    struct ImportSummary {
        var added = 0
        var skipped = 0
        var shelvesAdded = 0
        var message: String {
            "Added \(added) \(added == 1 ? "title" : "titles") and \(shelvesAdded) new \(shelvesAdded == 1 ? "shelf" : "shelves"). \(skipped) \(skipped == 1 ? "title was" : "titles were") already in your library."
        }
    }
    enum ArchiveError: LocalizedError {
        case unsupportedVersion
        case invalidData(String)
        var errorDescription: String? {
            switch self {
            case .unsupportedVersion: return "This backup uses a newer format. Update App Shelf before importing it."
            case .invalidData(let message): return "This backup could not be imported. \(message)"
            }
        }
    }

    init(shelves: [Shelf], tags: [MoodTag], items: [MediaItem], exportedAt: Date = .now) {
        self.exportedAt = exportedAt
        self.shelves = shelves.map { ShelfRecord(name: $0.name, seedKey: $0.seedKey, position: $0.position) }
        self.tags = tags.map(\.label)
        self.items = items.map { item in
            ItemRecord(id: item.libraryID, title: item.title, creator: item.creator, mediaType: item.mediaType,
                       shelfIndex: shelves.firstIndex { $0.persistentModelID == item.shelf?.persistentModelID },
                       position: item.positionInShelf, createdAt: item.createdAt, started: item.startedDate,
                       finished: item.finishedDate, rating: item.rating, notes: item.notes,
                       favorite: item.isFavorite, current: item.progressCurrent, total: item.progressTotal,
                       unit: item.progressUnit, tags: item.moodTags.map(\.label), cover: item.coverImageData)
        }
    }

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    static func decode(_ data: Data) throws -> LibraryArchive {
        guard data.count <= 50_000_000 else { throw ArchiveError.invalidData("The file is larger than 50 MB.") }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let archive = try decoder.decode(LibraryArchive.self, from: data)
        try archive.validate()
        return archive
    }

    func validate() throws {
        guard version == 1 else { throw ArchiveError.unsupportedVersion }
        guard shelves.count <= 1000 && items.count <= 10_000 && tags.count <= 1000 else {
            throw ArchiveError.invalidData("The file contains too many records.")
        }
        guard Set(items.map(\.id)).count == items.count else { throw ArchiveError.invalidData("Some item identifiers are duplicated.") }
        for shelf in shelves {
            guard !shelf.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ArchiveError.invalidData("A shelf has no name.") }
        }
        for item in items {
            guard !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ArchiveError.invalidData("An item has no title.") }
            if let index = item.shelfIndex, !shelves.indices.contains(index) { throw ArchiveError.invalidData("An item refers to a missing shelf.") }
            if let rating = item.rating, !(1...5).contains(rating) { throw ArchiveError.invalidData("A rating is outside the 1–5 range.") }
            guard item.current >= 0 && item.total >= 0 && (item.total == 0 || item.current <= item.total) else {
                throw ArchiveError.invalidData("An item has invalid progress.")
            }
        }
    }

    /// Adds only missing records. Existing titles, notes, and progress are never overwritten.
    @MainActor
    func merge(into context: ModelContext) throws -> ImportSummary {
        try validate()
        do { return try mergeValidatedRecords(into: context) }
        catch { context.rollback(); throw error }
    }

    @MainActor
    private func mergeValidatedRecords(into context: ModelContext) throws -> ImportSummary {
        var summary = ImportSummary()
        let existingShelves = try context.fetch(FetchDescriptor<Shelf>(sortBy: [SortDescriptor(\Shelf.position)]))
        var allShelves = existingShelves
        var resolvedShelves: [Shelf] = []
        var allTags = try context.fetch(FetchDescriptor<MoodTag>())
        var existingIDs = Set(try context.fetch(FetchDescriptor<MediaItem>()).map(\.libraryID))
        for record in shelves {
            if let shelf = allShelves.first(where: {
                if let key = record.seedKey, $0.seedKey == key { return true }
                return $0.name.localizedStandardCompare(record.name) == .orderedSame
            }) { resolvedShelves.append(shelf) }
            else {
                let shelf = Shelf(name: record.name, position: (allShelves.map(\.position).max() ?? -1) + 1,
                                  isDefault: record.seedKey.flatMap(Shelf.builtInDefinition(forSeedKey:)) != nil,
                                  seedKey: record.seedKey)
                context.insert(shelf); allShelves.append(shelf); resolvedShelves.append(shelf); summary.shelvesAdded += 1
            }
        }
        for label in Set(tags + items.flatMap(\.tags)) where !allTags.contains(where: { $0.label == label }) {
            let tag = MoodTag(label: label); context.insert(tag); allTags.append(tag)
        }
        var unsortedShelf: Shelf?
        for record in items.sorted(by: {
            if $0.shelfIndex != $1.shelfIndex { return ($0.shelfIndex ?? -1) < ($1.shelfIndex ?? -1) }
            return $0.position < $1.position
        }) {
            guard !existingIDs.contains(record.id) else { summary.skipped += 1; continue }
            let shelf: Shelf
            if let index = record.shelfIndex { shelf = resolvedShelves[index] }
            else {
                if unsortedShelf == nil {
                    unsortedShelf = allShelves.first(where: { $0.name == "Unsorted" })
                    if unsortedShelf == nil {
                        let newShelf = Shelf(name: "Unsorted", position: (allShelves.map(\.position).max() ?? -1) + 1)
                        context.insert(newShelf); allShelves.append(newShelf); unsortedShelf = newShelf; summary.shelvesAdded += 1
                    }
                }
                shelf = unsortedShelf!
            }
            let item = MediaItem(title: record.title, mediaType: record.mediaType, shelf: shelf, positionInShelf: shelf.nextItemPosition)
            item.libraryID = record.id; item.creator = record.creator; item.createdAt = record.createdAt
            item.startedDate = record.started; item.finishedDate = record.finished; item.rating = record.rating
            item.notes = record.notes; item.isFavorite = record.favorite; item.progressCurrent = record.current
            item.progressTotal = record.total; item.progressUnit = record.unit; item.coverImageData = record.cover
            item.moodTags = allTags.filter { record.tags.contains($0.label) }
            context.insert(item); existingIDs.insert(record.id); summary.added += 1
        }
        for shelf in allShelves { shelf.normalizeItemPositions() }
        try context.save()
        return summary
    }
}
