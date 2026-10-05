import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Shelf.position) private var shelves: [Shelf]
    @Query private var items: [MediaItem]
    @Query private var tags: [MoodTag]
    @State private var showAddShelf = false
    @State private var shelfToEdit: Shelf?
    @State private var shelvesToDelete: [Shelf] = []
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var backupDocument: LibraryBackupDocument?
    @State private var pendingArchive: LibraryArchive?
    @State private var feedback: String?
    #if os(iOS)
    @State private var editMode: EditMode = .inactive
    #endif

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(shelves) { shelf in
                        Button { shelfToEdit = shelf } label: {
                            HStack(spacing: 12) {
                                Image(systemName: shelf.systemImage)
                                    .foregroundStyle(ShelfStyle.sageForeground).frame(width: 25)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(shelf.name).foregroundStyle(.primary)
                                    Text("\(shelf.items.count) \(shelf.items.count == 1 ? "title" : "titles")\(shelf.isDefault ? " · Built-in shelf" : "")")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                        .deleteDisabled(shelf.isDefault)
                    }
                    .onMove(perform: moveShelf)
                    .onDelete { offsets in shelvesToDelete = offsets.map { shelves[$0] }.filter { !$0.isDefault } }
                    Button { showAddShelf = true } label: { Label("Add a shelf", systemImage: "plus") }
                } header: { Text("Your shelves") } footer: {
                    Text("Rename shelves to fit your life. Built-in shelves keep their behavior when renamed. Deleting a custom shelf also deletes its titles.")
                }

                Section {
                    Button(action: exportBackup) { Label("Export library backup", systemImage: "square.and.arrow.up") }
                    Button { showImporter = true } label: { Label("Import a backup", systemImage: "square.and.arrow.down") }
                    LabeledContent("In your library", value: "\(items.count) titles")
                } header: { Text("Keep your collection safe") } footer: {
                    Text("Backups include shelves, covers, progress, notes, ratings, and vibes. Import adds missing titles and leaves existing titles unchanged.")
                }

                Section("About App Shelf") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("A shelf for every story.").font(.system(.headline, design: .serif))
                        Text("A quiet home for everything you’re playing, watching, reading, and listening to.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }.padding(.vertical, 8)
                    LabeledContent("Version", value: "1.1")
                    LabeledContent("Storage", value: "On device · iCloud when available")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                #if os(iOS)
                EditButton()
                #endif
            }
            #if os(iOS)
            .environment(\.editMode, $editMode)
            #endif
            .sheet(isPresented: $showAddShelf) { ShelfEditorView() }
            .sheet(item: $shelfToEdit) { ShelfEditorView(editing: $0) }
            .sheet(isPresented: Binding(get: { pendingArchive != nil }, set: { if !$0 { pendingArchive = nil } })) {
                if let archive = pendingArchive {
                    ImportArchivePreview(archive: archive) {
                        do { feedback = try archive.merge(into: context).message }
                        catch { context.rollback(); feedback = error.localizedDescription }
                        pendingArchive = nil
                    } cancel: { pendingArchive = nil }
                }
            }
            .fileExporter(isPresented: $showExporter, document: backupDocument, contentType: .json,
                          defaultFilename: "App-Shelf-Backup") { result in
                if case .failure(let error) = result { feedback = error.localizedDescription }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
                do {
                    let url = try result.get()
                    let access = url.startAccessingSecurityScopedResource()
                    defer { if access { url.stopAccessingSecurityScopedResource() } }
                    let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                    guard size <= 50_000_000 else { throw LibraryArchive.ArchiveError.invalidData("The file is larger than 50 MB.") }
                    pendingArchive = try LibraryArchive.decode(Data(contentsOf: url))
                } catch { feedback = error.localizedDescription }
            }
            .confirmationDialog("Delete these shelves?", isPresented: Binding(
                get: { !shelvesToDelete.isEmpty }, set: { if !$0 { shelvesToDelete = [] } }
            ), titleVisibility: .visible) {
                Button("Delete \(shelvesToDelete.count) \(shelvesToDelete.count == 1 ? "shelf" : "shelves")", role: .destructive) {
                    deletePendingShelves()
                }
            } message: {
                Text("This also removes \(shelvesToDelete.reduce(0) { $0 + $1.items.count }) titles and their notes. Export a backup first if you want to keep them.")
            }
            .alert("App Shelf", isPresented: Binding(get: { feedback != nil }, set: { if !$0 { feedback = nil } })) {
                Button("OK", role: .cancel) { feedback = nil }
            } message: { Text(feedback ?? "") }
        }
        .tint(ShelfStyle.sageForeground)
    }

    private func exportBackup() {
        do {
            let archive = LibraryArchive(shelves: shelves, tags: tags, items: items)
            try context.save()
            backupDocument = LibraryBackupDocument(data: try archive.encoded())
            showExporter = true
        } catch { feedback = error.localizedDescription }
    }
    private func moveShelf(from source: IndexSet, to destination: Int) {
        var reordered = shelves
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, shelf) in reordered.enumerated() { shelf.position = index }
        do { try context.save() }
        catch { context.rollback(); feedback = error.localizedDescription }
    }
    private func deletePendingShelves() {
        for shelf in shelvesToDelete { context.delete(shelf) }
        shelvesToDelete = []
        do { try context.save() }
        catch { context.rollback(); feedback = error.localizedDescription }
    }
}

private struct ImportArchivePreview: View {
    let archive: LibraryArchive
    let confirm: () -> Void
    let cancel: () -> Void
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: "tray.and.arrow.down.fill").font(.largeTitle).foregroundStyle(ShelfStyle.sageForeground)
                Text("Bring your collection home.").font(.system(.title2, design: .serif))
                Text("This backup contains \(archive.items.count) titles across \(archive.shelves.count) shelves.")
                Text("Exported \(archive.exportedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption).foregroundStyle(.secondary)
                Text("Missing titles will be added. Existing titles and notes stay as they are. Importing the same backup again won’t create duplicates.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Button("Import library", action: confirm).buttonStyle(.borderedProminent).tint(ShelfStyle.sage)
                Spacer(minLength: 0)
            }
            .padding(28)
            .navigationTitle("Import backup")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: cancel) } }
        }
        #if os(macOS)
        .frame(width: 480, height: 440)
        #else
        .presentationDetents([.medium, .large])
        #endif
    }
}
