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
        let builtInsChanged = reconcileBuiltInData(context: context)
        let identifiersChanged = MediaItem.reconcileLibraryIdentifiers(context: context)
        let didChange = builtInsChanged || identifiersChanged

        if didChange {
            try? context.save()
        }

        if didChange || requirements.needsAnyData || !defaults.bool(forKey: seededKey) {
            defaults.set(true, forKey: seededKey)
        }
    }

    static func seed(context: ModelContext) {
        _ = reconcileBuiltInData(context: context)
        MediaItem.reconcileLibraryIdentifiers(context: context)
        try? context.save()
    }

    static func seedRequirements(context: ModelContext) -> SeedRequirements {
        let shelves = (try? context.fetch(FetchDescriptor<Shelf>())) ?? []
        let tags = (try? context.fetch(FetchDescriptor<MoodTag>())) ?? []

        return SeedRequirements(
            needsShelves: Shelf.builtInDefinitions.contains(where: { matchingShelves(for: $0, in: shelves).isEmpty }),
            needsMoodTags: MoodTag.builtInDefinitions.contains(where: { matchingTags(for: $0, in: tags).isEmpty })
        )
    }

    @discardableResult
    static func reconcileBuiltInData(context: ModelContext) -> Bool {
        var didChange = false
        didChange = reconcileShelves(context: context) || didChange
        didChange = reconcileMoodTags(context: context) || didChange
        return didChange
    }

    private static func reconcileShelves(context: ModelContext) -> Bool {
        let shelves = (try? context.fetch(FetchDescriptor<Shelf>())) ?? []
        var didChange = false

        for definition in Shelf.builtInDefinitions {
            let matches = matchingShelves(for: definition, in: shelves)

            guard let canonical = canonicalShelf(for: definition, among: matches) else {
                context.insert(
                    Shelf(
                        name: definition.name,
                        position: definition.position,
                        isDefault: true,
                        seedKey: definition.seedKey
                    )
                )
                didChange = true
                continue
            }

            if canonical.seedKey != definition.seedKey {
                canonical.seedKey = definition.seedKey
                didChange = true
            }

            if !canonical.isDefault {
                canonical.isDefault = true
                didChange = true
            }

            let duplicates = matches.filter { $0.persistentModelID != canonical.persistentModelID }
            if !duplicates.isEmpty {
                mergeDuplicateShelves(duplicates, into: canonical, context: context)
                didChange = true
            }
        }

        return didChange
    }

    private static func reconcileMoodTags(context: ModelContext) -> Bool {
        let tags = (try? context.fetch(FetchDescriptor<MoodTag>())) ?? []
        var didChange = false

        for definition in MoodTag.builtInDefinitions {
            let matches = matchingTags(for: definition, in: tags)

            guard let canonical = canonicalTag(for: definition, among: matches) else {
                context.insert(MoodTag(label: definition.label, seedKey: definition.seedKey))
                didChange = true
                continue
            }

            if canonical.seedKey != definition.seedKey {
                canonical.seedKey = definition.seedKey
                didChange = true
            }

            let duplicates = matches.filter { $0.persistentModelID != canonical.persistentModelID }
            if !duplicates.isEmpty {
                mergeDuplicateTags(duplicates, into: canonical, context: context)
                didChange = true
            }
        }

        return didChange
    }

    private static func matchingShelves(
        for definition: Shelf.BuiltInDefinition,
        in shelves: [Shelf]
    ) -> [Shelf] {
        shelves.filter { shelf in
            if shelf.seedKey == definition.seedKey {
                return true
            }

            return shelf.seedKey == nil && shelf.isDefault && shelf.name == definition.name
        }
    }

    private static func matchingTags(
        for definition: MoodTag.BuiltInDefinition,
        in tags: [MoodTag]
    ) -> [MoodTag] {
        tags.filter { tag in
            if tag.seedKey == definition.seedKey {
                return true
            }

            return tag.seedKey == nil && tag.label == definition.label
        }
    }

    private static func canonicalShelf(
        for definition: Shelf.BuiltInDefinition,
        among matches: [Shelf]
    ) -> Shelf? {
        matches.min { lhs, rhs in
            let lhsHasSeedKey = lhs.seedKey == definition.seedKey
            let rhsHasSeedKey = rhs.seedKey == definition.seedKey

            if lhsHasSeedKey != rhsHasSeedKey {
                return lhsHasSeedKey
            }

            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt < rhs.createdAt
            }

            if lhs.position != rhs.position {
                return lhs.position < rhs.position
            }

            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    private static func canonicalTag(
        for definition: MoodTag.BuiltInDefinition,
        among matches: [MoodTag]
    ) -> MoodTag? {
        matches.min { lhs, rhs in
            let lhsHasSeedKey = lhs.seedKey == definition.seedKey
            let rhsHasSeedKey = rhs.seedKey == definition.seedKey

            if lhsHasSeedKey != rhsHasSeedKey {
                return lhsHasSeedKey
            }

            let lhsIdentifier = PersistentIdentifierCoder.encode(lhs.persistentModelID)
            let rhsIdentifier = PersistentIdentifierCoder.encode(rhs.persistentModelID)
            return lhsIdentifier < rhsIdentifier
        }
    }

    private static func mergeDuplicateShelves(
        _ duplicates: [Shelf],
        into canonical: Shelf,
        context: ModelContext
    ) {
        var nextPosition = canonical.nextItemPosition
        let orderedDuplicates = duplicates.sorted { lhs, rhs in
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt < rhs.createdAt
            }

            if lhs.position != rhs.position {
                return lhs.position < rhs.position
            }

            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }

        for duplicate in orderedDuplicates {
            for item in duplicate.sortedItems {
                item.shelf = canonical
                item.positionInShelf = nextPosition
                nextPosition += 1
            }
            context.delete(duplicate)
        }

        canonical.normalizeItemPositions()
    }

    private static func mergeDuplicateTags(
        _ duplicates: [MoodTag],
        into canonical: MoodTag,
        context: ModelContext
    ) {
        for duplicate in duplicates {
            let affectedItems = duplicate.items

            for item in affectedItems {
                var updatedTags = item.moodTags.filter { $0.persistentModelID != duplicate.persistentModelID }
                if !updatedTags.contains(where: { $0.persistentModelID == canonical.persistentModelID }) {
                    updatedTags.append(canonical)
                }
                item.moodTags = updatedTags
            }
            context.delete(duplicate)
        }
    }
}
