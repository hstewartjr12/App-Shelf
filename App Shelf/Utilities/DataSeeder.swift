import Foundation
import SwiftData

@MainActor
enum DataSeeder {
    private static let seededKey = "AppShelf.hasSeeded"

    struct SeedRequirements: Equatable {
        let needsShelves: Bool
        let needsMoodTags: Bool

        var needsAnyData: Bool {
            needsShelves || needsMoodTags
        }
    }

    static func seedIfNeeded(context: ModelContext, defaults: UserDefaults = .standard) {
        let requirements = seedRequirements(context: context)

        if requirements.needsShelves {
            seedShelves(context: context)
        }

        if requirements.needsMoodTags {
            seedMoodTags(context: context)
        }

        if requirements.needsAnyData {
            try? context.save()
        }

        if requirements.needsAnyData || !defaults.bool(forKey: seededKey) {
            defaults.set(true, forKey: seededKey)
        }
    }

    static func seed(context: ModelContext) {
        seedShelves(context: context)
        seedMoodTags(context: context)
        try? context.save()
    }

    static func seedRequirements(context: ModelContext) -> SeedRequirements {
        let shelfCount = (try? context.fetchCount(FetchDescriptor<Shelf>())) ?? 0
        let tagCount = (try? context.fetchCount(FetchDescriptor<MoodTag>())) ?? 0

        return SeedRequirements(
            needsShelves: shelfCount == 0,
            needsMoodTags: tagCount == 0
        )
    }

    private static func seedShelves(context: ModelContext) {
        for (name, position) in Shelf.defaultShelves {
            let shelf = Shelf(name: name, position: position, isDefault: true)
            context.insert(shelf)
        }
    }

    private static func seedMoodTags(context: ModelContext) {
        for label in MoodTag.defaults {
            let tag = MoodTag(label: label)
            context.insert(tag)
        }
    }
}
