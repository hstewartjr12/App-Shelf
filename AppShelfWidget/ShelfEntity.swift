import AppIntents
import SwiftData

struct ShelfEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Shelf"
    static var defaultQuery = ShelfEntityQuery()

    let id: String
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct ShelfEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ShelfEntity] {
        let container = AppShelfContainer.create()
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Shelf>(sortBy: [SortDescriptor(\.position)])
        let shelves = try context.fetch(descriptor)
        let decodedIdentifiers = Set(identifiers.compactMap(PersistentIdentifierCoder.decode))

        return shelves
            .filter { decodedIdentifiers.contains($0.persistentModelID) }
            .map { ShelfEntity(id: PersistentIdentifierCoder.encode($0.persistentModelID), name: $0.name) }
    }

    func suggestedEntities() async throws -> [ShelfEntity] {
        let container = AppShelfContainer.create()
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Shelf>(sortBy: [SortDescriptor(\.position)])
        let shelves = try context.fetch(descriptor)
        return shelves.map {
            ShelfEntity(id: PersistentIdentifierCoder.encode($0.persistentModelID), name: $0.name)
        }
    }
}
