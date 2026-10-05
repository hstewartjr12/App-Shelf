import Foundation

enum LibrarySort: String, CaseIterable, Identifiable {
    case newest = "Recently added"
    case title = "Title A–Z"
    case rating = "Highest rated"
    case progress = "Closest to finished"
    var id: Self { self }
}

struct LibraryQuery {
    var search = ""
    var mediaType: MediaType?
    var shelf: Shelf?
    var favoritesOnly = false
    var sort: LibrarySort = .newest

    func results(in items: [MediaItem]) -> [MediaItem] {
        let words = search.split(whereSeparator: \.isWhitespace).map(String.init)
        return items.filter { item in
            if let mediaType, item.mediaType != mediaType { return false }
            if let shelf, item.shelf?.persistentModelID != shelf.persistentModelID { return false }
            if favoritesOnly && !item.isFavorite { return false }
            let text = ([item.title, item.creator, item.notes, item.shelf?.name ?? "", item.mediaType.displayName]
                + item.moodTags.map(\.label)).joined(separator: " ")
            return words.allSatisfy { text.localizedStandardContains($0) }
        }.sorted { lhs, rhs in
            switch sort {
            case .newest:
                if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
            case .rating:
                if lhs.rating != rhs.rating { return (lhs.rating ?? 0) > (rhs.rating ?? 0) }
            case .progress:
                if lhs.progressFraction != rhs.progressFraction {
                    return (lhs.progressFraction ?? -1) > (rhs.progressFraction ?? -1)
                }
            case .title: break
            }
            return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        }
    }
}
