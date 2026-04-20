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

enum PersistentIdentifierCoder {
    private static let decoder = JSONDecoder()
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    static func encode(_ identifier: PersistentIdentifier) -> String {
        do {
            let data = try encoder.encode(identifier)
            return data.base64EncodedString()
        } catch {
            fatalError("Failed to encode PersistentIdentifier: \(error)")
        }
    }

    static func decode(_ string: String) -> PersistentIdentifier? {
        guard let data = Data(base64Encoded: string) else { return nil }
        return try? decoder.decode(PersistentIdentifier.self, from: data)
    }
}
