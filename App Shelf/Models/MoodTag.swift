import Foundation
import SwiftData

@Model
final class MoodTag {
    @Attribute(.unique)
    var label: String
    var items: [MediaItem]

    init(label: String) {
        self.label = label
        self.items = []
    }
}

extension MoodTag {
    static let defaults: [String] = [
        "cozy", "intense", "mid", "masterpiece",
        "chill", "emotional", "funny", "dark"
    ]
}
