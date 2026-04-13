import SwiftData
import Foundation

enum AppShelfContainer {
    static let appGroupIdentifier = "group.com.appshelf.shared"

    static func create() -> ModelContainer {
        let schema = Schema([MediaItem.self, Shelf.self, MoodTag.self])
        let url = containerURL
        let config = ModelConfiguration(
            "AppShelf",
            schema: schema,
            url: url,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Fallback to in-memory container on schema migration issues during development
            let fallback = ModelConfiguration(isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [fallback])
        }
    }

    static var containerURL: URL {
        let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        // On macOS Simulator / without a provisioned App Group, fall back to app support directory
        let base = groupURL ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("AppShelf.store")
    }
}
