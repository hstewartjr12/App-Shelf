import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Shelf.position) private var shelves: [Shelf]
    @State private var showAddShelf = false
    @State private var shelfToEdit: Shelf?
    #if os(iOS)
    @State private var editMode: EditMode = .inactive
    #endif

    var body: some View {
        NavigationStack {
            List {
                Section("Shelves") {
                    ForEach(shelves) { shelf in
                        HStack {
                            Text(shelf.name)
                            Spacer()
                            if shelf.isDefault {
                                Text("Default")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            shelfToEdit = shelf
                        }
                    }
                    .onMove(perform: moveShelf)
                    .onDelete(perform: deleteShelf)

                    Button {
                        showAddShelf = true
                    } label: {
                        Label("Add Shelf", systemImage: "plus")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Storage", value: "Local only — no account needed")
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
            .sheet(isPresented: $showAddShelf) {
                ShelfEditorView()
            }
            .sheet(item: $shelfToEdit) { shelf in
                ShelfEditorView(editing: shelf)
            }
        }
    }

    private func moveShelf(from source: IndexSet, to destination: Int) {
        var reordered = shelves
        reordered.move(fromOffsets: source, toOffset: destination)
        for (idx, shelf) in reordered.enumerated() {
            shelf.position = idx
        }
        try? context.save()
    }

    private func deleteShelf(at offsets: IndexSet) {
        for idx in offsets {
            let shelf = shelves[idx]
            guard !shelf.isDefault else { continue }
            context.delete(shelf)
        }
        try? context.save()
    }
}
