import Foundation
import SwiftData

@Model
final class MediaItem {
    var title: String
    var coverImageData: Data?
    var notes: String
    var rating: Int?
    var startedDate: Date?
    var finishedDate: Date?
    var mediaType: MediaType
    var createdAt: Date
    var positionInShelf: Int

    var shelf: Shelf?
    var moodTags: [MoodTag]

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
        self.moodTags = []
    }
}
