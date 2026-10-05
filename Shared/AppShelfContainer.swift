import SwiftData
import Foundation
import CoreData

enum AppShelfContainer {
    static let appGroupIdentifier = "group.com.appshelf.shared"
    static let cloudKitContainerIdentifier = "iCloud.com.appshelf.AppShelf"

    static var isDemoLibrary: Bool {
        #if DEBUG
        ProcessInfo.processInfo.environment["APPSHELF_DEMO_LIBRARY"] == "1"
        #else
        false
        #endif
    }

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
        if isDemoLibrary {
            return try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        }
        let url = persistentStoreURL()
        let cloudKitDatabase = shouldUseCloudKit()
            ? ModelConfiguration.CloudKitDatabase.private(cloudKitContainerIdentifier)
            : .none

        do {
            return try makeContainer(url: url, cloudKitDatabase: cloudKitDatabase)
        } catch {
            do {
                return try makeContainer(url: url, cloudKitDatabase: .none)
            } catch {
                let fallback = ModelConfiguration(isStoredInMemoryOnly: true)
                return try! ModelContainer(for: schema, configurations: [fallback])
            }
        }
    }

    #if DEBUG
    static func initializeCloudKitSchemaIfRequested(platform: PersistencePlatform = .current) {
        guard ProcessInfo.processInfo.environment["APPSHELF_INIT_CLOUDKIT_SCHEMA"] == "1" else {
            return
        }

        let url = persistentStoreURL(platform: platform)
        let configuration = makeConfiguration(
            url: url,
            cloudKitDatabase: .private(cloudKitContainerIdentifier)
        )

        do {
            try autoreleasepool {
                let description = NSPersistentStoreDescription(url: configuration.url)
                description.cloudKitContainerOptions = .init(containerIdentifier: cloudKitContainerIdentifier)
                description.shouldAddStoreAsynchronously = false

                guard let model = NSManagedObjectModel.makeManagedObjectModel(for: [MediaItem.self, Shelf.self, MoodTag.self]) else {
                    return
                }

                let container = NSPersistentCloudKitContainer(name: "AppShelf", managedObjectModel: model)
                container.persistentStoreDescriptions = [description]
                var loadError: Error?
                container.loadPersistentStores { _, error in
                    loadError = error
                }

                if let loadError {
                    throw loadError
                }

                try container.initializeCloudKitSchema()

                if let store = container.persistentStoreCoordinator.persistentStores.first {
                    try container.persistentStoreCoordinator.remove(store)
                }
            }
        } catch {
            return
        }
    }
    #endif

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

    private static let schema = Schema([MediaItem.self, Shelf.self, MoodTag.self])

    static func createLocalOnlyContainer(
        platform: PersistencePlatform = .current
    ) throws -> ModelContainer {
        try makeContainer(url: persistentStoreURL(platform: platform), cloudKitDatabase: .none)
    }

    static func shouldUseCloudKit(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        infoDictionary: [String: Any]? = Bundle.main.infoDictionary
    ) -> Bool {
        if environment["APPSHELF_DISABLE_CLOUDKIT"] == "1" {
            return false
        }

        if environment["XCTestConfigurationFilePath"] != nil || environment["XCTestSessionIdentifier"] != nil {
            return false
        }

        if infoDictionary?["NSExtension"] != nil {
            return false
        }

        return true
    }

    private static func makeContainer(
        url: URL,
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase
    ) throws -> ModelContainer {
        try ModelContainer(for: schema, configurations: [makeConfiguration(url: url, cloudKitDatabase: cloudKitDatabase)])
    }

    private static func makeConfiguration(
        url: URL,
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase
    ) -> ModelConfiguration {
        ModelConfiguration(
            "AppShelf",
            schema: schema,
            url: url,
            cloudKitDatabase: cloudKitDatabase
        )
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
