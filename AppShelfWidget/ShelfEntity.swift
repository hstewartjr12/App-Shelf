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
        return shelves
            .filter { identifiers.contains($0.persistentModelID.hashValue.description) }
            .map { ShelfEntity(id: $0.persistentModelID.hashValue.description, name: $0.name) }
    }

    func suggestedEntities() async throws -> [ShelfEntity] {
        let container = AppShelfContainer.create()
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Shelf>(sortBy: [SortDescriptor(\.position)])
        let shelves = try context.fetch(descriptor)
        return shelves.map {
            ShelfEntity(id: $0.persistentModelID.hashValue.description, name: $0.name)
        }
    }
}
