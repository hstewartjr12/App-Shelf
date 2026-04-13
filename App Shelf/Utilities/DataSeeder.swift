import Foundation
import SwiftData

@MainActor
enum DataSeeder {
    private static let seededKey = "AppShelf.hasSeeded"

    static func seedIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }
        seed(context: context)
        UserDefaults.standard.set(true, forKey: seededKey)
    }

    static func seed(context: ModelContext) {
        // Seed default shelves
        for (name, position) in Shelf.defaultShelves {
            let shelf = Shelf(name: name, position: position, isDefault: true)
            context.insert(shelf)
        }

        // Seed default mood tags
        for label in MoodTag.defaults {
            let tag = MoodTag(label: label)
            context.insert(tag)
        }

        try? context.save()
    }
}
