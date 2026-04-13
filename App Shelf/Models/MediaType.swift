import Foundation

enum MediaType: String, Codable, CaseIterable, Identifiable {
    case game, show, movie, book, music, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .game: return "Game"
        case .show: return "Show"
        case .movie: return "Movie"
        case .book: return "Book"
        case .music: return "Music"
        case .other: return "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .game: return "gamecontroller.fill"
        case .show: return "tv.fill"
        case .movie: return "film.fill"
        case .book: return "book.fill"
        case .music: return "music.note"
        case .other: return "square.grid.2x2.fill"
        }
    }

    var accentColor: String {
        switch self {
        case .game: return "purple"
        case .show: return "blue"
        case .movie: return "red"
        case .book: return "green"
        case .music: return "pink"
        case .other: return "orange"
        }
    }
}
