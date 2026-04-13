import Testing
import Foundation
@testable import App_Shelf

@Suite("MediaType")
struct MediaTypeTests {

    @Test("All cases are unique", arguments: MediaType.allCases)
    func idIsRawValue(type: MediaType) {
        #expect(type.id == type.rawValue)
    }

    @Test("Exactly 6 cases exist")
    func caseCount() {
        #expect(MediaType.allCases.count == 6)
    }

    @Test("All IDs are unique")
    func uniqueIDs() {
        let ids = MediaType.allCases.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("displayName is non-empty", arguments: MediaType.allCases)
    func displayNameNonEmpty(type: MediaType) {
        #expect(!type.displayName.isEmpty)
    }

    @Test("systemImage is non-empty", arguments: MediaType.allCases)
    func systemImageNonEmpty(type: MediaType) {
        #expect(!type.systemImage.isEmpty)
    }

    @Test("accentColor is non-empty", arguments: MediaType.allCases)
    func accentColorNonEmpty(type: MediaType) {
        #expect(!type.accentColor.isEmpty)
    }

    @Test("Expected displayNames")
    func displayNames() {
        #expect(MediaType.game.displayName == "Game")
        #expect(MediaType.show.displayName == "Show")
        #expect(MediaType.movie.displayName == "Movie")
        #expect(MediaType.book.displayName == "Book")
        #expect(MediaType.music.displayName == "Music")
        #expect(MediaType.other.displayName == "Other")
    }

    @Test("Expected accentColors")
    func accentColors() {
        #expect(MediaType.game.accentColor == "purple")
        #expect(MediaType.show.accentColor == "blue")
        #expect(MediaType.movie.accentColor == "red")
        #expect(MediaType.book.accentColor == "green")
        #expect(MediaType.music.accentColor == "pink")
        #expect(MediaType.other.accentColor == "orange")
    }

    @Test("Raw value round-trips through Codable", arguments: MediaType.allCases)
    func codableRoundTrip(type: MediaType) throws {
        let data = try JSONEncoder().encode(type)
        let decoded = try JSONDecoder().decode(MediaType.self, from: data)
        #expect(decoded == type)
    }
}
