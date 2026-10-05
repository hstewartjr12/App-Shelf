import Foundation
import SwiftData

@Model
final class MoodTag {
    var label: String = ""
    var seedKey: String?
    @Relationship(originalName: "items")
    var storedItems: [MediaItem]? = []

    var items: [MediaItem] {
        get { storedItems ?? [] }
        set { storedItems = newValue }
    }

    init(label: String, seedKey: String? = nil) {
        self.label = label
        self.seedKey = seedKey
        self.storedItems = []
    }
}

extension MoodTag {
    struct BuiltInDefinition: Equatable {
        let seedKey: String
        let label: String
    }

    static let builtInDefinitions: [BuiltInDefinition] = [
        .init(seedKey: "tag.cozy", label: "cozy"),
        .init(seedKey: "tag.intense", label: "intense"),
        .init(seedKey: "tag.mid", label: "mid"),
        .init(seedKey: "tag.masterpiece", label: "masterpiece"),
        .init(seedKey: "tag.chill", label: "chill"),
        .init(seedKey: "tag.emotional", label: "emotional"),
        .init(seedKey: "tag.funny", label: "funny"),
        .init(seedKey: "tag.dark", label: "dark")
    ]

    static let defaults: [String] = [
        "cozy", "intense", "mid", "masterpiece",
        "chill", "emotional", "funny", "dark"
    ]

    static func builtInDefinition(forSeedKey seedKey: String) -> BuiltInDefinition? {
        builtInDefinitions.first(where: { $0.seedKey == seedKey })
    }

    static func builtInDefinition(matchingLegacyLabel label: String) -> BuiltInDefinition? {
        builtInDefinitions.first(where: { $0.label == label })
    }
}
