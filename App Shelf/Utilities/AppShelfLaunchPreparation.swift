import SwiftData

@MainActor
enum AppShelfLaunchPreparation {
    static func prepareForSyncIfNeeded(platform: AppShelfContainer.PersistencePlatform = .current) {
        guard !AppShelfContainer.isDemoLibrary else { return }
        do {
            let container = try AppShelfContainer.createLocalOnlyContainer(platform: platform)
            let context = container.mainContext
            let builtInsChanged = DataSeeder.reconcileBuiltInData(context: context)
            let identifiersChanged = MediaItem.reconcileLibraryIdentifiers(context: context)
            if builtInsChanged || identifiersChanged {
                try? context.save()
            }
        } catch {
            return
        }
    }
}
