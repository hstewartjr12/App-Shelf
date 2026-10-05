import Foundation
import SwiftData

@Model
final class MediaItem {
    var title: String = ""
    var coverImageData: Data?
    var notes: String = ""
    var rating: Int?
    var startedDate: Date?
    var finishedDate: Date?
    var mediaType: MediaType = MediaType.other
    var createdAt: Date = Date.now
    var positionInShelf: Int = 0
    // An optional stored value prevents one migration default UUID being shared by every old record.
    @Attribute(originalName: "libraryID")
    var storedLibraryID: UUID?
    var creator: String = ""
    var isFavorite: Bool = false
    var progressCurrent: Int = 0
    var progressTotal: Int = 0
    var progressUnit: String = ""

    var shelf: Shelf?
    @Relationship(originalName: "moodTags", inverse: \MoodTag.storedItems)
    var storedMoodTags: [MoodTag]? = []

    var moodTags: [MoodTag] {
        get { storedMoodTags ?? [] }
        set { storedMoodTags = newValue }
    }

    var libraryID: UUID {
        get {
            if let storedLibraryID { return storedLibraryID }
            let identifier = UUID()
            storedLibraryID = identifier
            return identifier
        }
        set { storedLibraryID = newValue }
    }

    init(
        title: String,
        mediaType: MediaType = .other,
        shelf: Shelf? = nil,
        positionInShelf: Int = 0
    ) {
        self.title = title
        self.mediaType = mediaType
        self.shelf = shelf
        self.positionInShelf = positionInShelf
        self.notes = ""
        self.rating = nil
        self.coverImageData = nil
        self.createdAt = .now
        self.startedDate = .now
        self.finishedDate = nil
        self.storedMoodTags = []
        self.storedLibraryID = UUID()
    }
}

extension MediaItem {
    @MainActor
    @discardableResult
    static func reconcileLibraryIdentifiers(context: ModelContext) -> Bool {
        guard let items = try? context.fetch(FetchDescriptor<MediaItem>(
            sortBy: [SortDescriptor(\MediaItem.createdAt), SortDescriptor(\MediaItem.title)]
        )) else { return false }
        var seen: Set<UUID> = []
        var changed = false
        for item in items {
            if let identifier = item.storedLibraryID, !seen.contains(identifier) {
                seen.insert(identifier)
            } else {
                let identifier = UUID()
                item.storedLibraryID = identifier
                seen.insert(identifier)
                changed = true
            }
        }
        return changed
    }

    @discardableResult
    func move(to destinationShelf: Shelf, finishedShelfName: String = Shelf.finishedShelfName) -> Bool {
        guard shelf?.persistentModelID != destinationShelf.persistentModelID else {
            return false
        }

        let sourceShelf = shelf
        let wasOnFinishedShelf = sourceShelf?.isFinishedShelf == true || sourceShelf?.name == finishedShelfName
        let movingToFinishedShelf = destinationShelf.isFinishedShelf || destinationShelf.name == finishedShelfName
        let destinationPosition = destinationShelf.nextItemPosition

        shelf = destinationShelf
        positionInShelf = destinationPosition

        sourceShelf?.normalizeItemPositions(removing: self)
        destinationShelf.normalizeItemPositions()

        if movingToFinishedShelf && finishedDate == nil {
            finishedDate = .now
        } else if wasOnFinishedShelf && !movingToFinishedShelf {
            finishedDate = nil
        }

        if movingToFinishedShelf && progressTotal > 0 {
            progressCurrent = progressTotal
        }

        return true
    }

    var progressFraction: Double? {
        guard progressTotal > 0 else { return nil }
        return min(1, max(0, Double(progressCurrent) / Double(progressTotal)))
    }

    var displayProgressUnit: String {
        if !progressUnit.isEmpty { return progressUnit }
        switch mediaType {
        case .book: return "pages"
        case .show: return "episodes"
        case .game: return "hours"
        case .music: return "tracks"
        case .movie, .other: return "steps"
        }
    }
}
