import Foundation
import SwiftData

/// Editing is isolated from the model until Save; dismissing a draft has no side effects.
struct MediaItemDraft {
    var title: String
    var creator: String
    var notes: String
    var rating: Int?
    var mediaType: MediaType
    var shelf: Shelf?
    var favorite: Bool
    var current: Int
    var total: Int
    var unit: String
    var started: Date?
    var finished: Date?
    var tags: Set<String>
    var cover: Data?

    init(item: MediaItem) {
        title = item.title; creator = item.creator; notes = item.notes; rating = item.rating
        mediaType = item.mediaType; shelf = item.shelf; favorite = item.isFavorite
        current = item.progressCurrent; total = item.progressTotal; unit = item.progressUnit
        started = item.startedDate; finished = item.finishedDate
        tags = Set(item.moodTags.map(\.label)); cover = item.coverImageData
    }

    var validation: String? {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Add a title to save this item." }
        if current < 0 || total < 0 { return "Progress cannot be negative." }
        if total > 0 && current > total { return "Progress is higher than the total. Adjust one of the numbers." }
        if let started, let finished, finished < started { return "The finish date must be on or after the start date." }
        return nil
    }

    @MainActor
    func apply(to item: MediaItem, context: ModelContext, existingTags: [MoodTag]) {
        item.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        item.creator = creator.trimmingCharacters(in: .whitespacesAndNewlines)
        item.notes = notes; item.rating = rating; item.mediaType = mediaType; item.isFavorite = favorite
        item.coverImageData = cover
        if let shelf { item.move(to: shelf) }
        item.progressCurrent = current; item.progressTotal = total
        item.progressUnit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        item.startedDate = started; item.finishedDate = finished
        var resolvedTags = existingTags
        for label in tags where !resolvedTags.contains(where: { $0.label == label }) {
            let tag = MoodTag(label: label); context.insert(tag); resolvedTags.append(tag)
        }
        item.moodTags = resolvedTags.filter { tags.contains($0.label) }
    }
}
