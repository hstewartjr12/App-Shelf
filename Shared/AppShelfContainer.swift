import SwiftData
import Foundation

enum AppShelfContainer {
    static let appGroupIdentifier = "group.com.appshelf.shared"

    enum PersistencePlatform {
        case iOS
        case macOS

        static var current: PersistencePlatform {
            #if os(macOS)
            .macOS
            #else
            .iOS
            #endif
        }
    }

    static func create() -> ModelContainer {
        let schema = Schema([MediaItem.self, Shelf.self, MoodTag.self])
        let url = persistentStoreURL()
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

    static func persistentStoreURL(
        fileManager: FileManager = .default,
        platform: PersistencePlatform = .current
    ) -> URL {
        let applicationSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let url = persistentStoreURL(
            appGroupURL: fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier),
            applicationSupportURL: applicationSupportURL,
            platform: platform
        )

        let directoryURL = url.deletingLastPathComponent()
        try? fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        return url
    }

    static func persistentStoreURL(
        appGroupURL: URL?,
        applicationSupportURL: URL,
        platform: PersistencePlatform
    ) -> URL {
        switch platform {
        case .iOS:
            let baseURL = appGroupURL ?? applicationSupportURL
            return baseURL.appendingPathComponent("AppShelf.store")
        case .macOS:
            return applicationSupportURL
                .appendingPathComponent("App Shelf", isDirectory: true)
                .appendingPathComponent("AppShelf.store")
        }
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
