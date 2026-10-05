import SwiftUI
import SwiftData

struct ShelfEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Shelf.position) private var shelves: [Shelf]

    var editingShelf: Shelf?
    @State private var name: String
    @State private var saveError: String?

    private var duplicateName: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return shelves.contains {
            $0.persistentModelID != editingShelf?.persistentModelID && $0.name.localizedStandardCompare(trimmed) == .orderedSame
        }
    }

    init(editing shelf: Shelf? = nil) {
        self.editingShelf = shelf
        _name = State(initialValue: shelf?.name ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Shelf name", text: $name)
                    if duplicateName {
                        Text("A shelf with that name already exists.").font(.caption).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(editingShelf == nil ? "New Shelf" : "Rename Shelf")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editingShelf == nil ? "Add" : "Save") {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || duplicateName)
                    .fontWeight(.semibold)
                }
            }
        }
        .shelfSaveAlert($saveError)
        #if os(macOS)
        .frame(minWidth: 360, minHeight: 180)
        #else
        .presentationDetents([.height(200)])
        #endif
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty && !duplicateName else { return }

        if let shelf = editingShelf {
            shelf.name = trimmed
        } else {
            let newPosition = (shelves.map(\.position).max() ?? -1) + 1
            let shelf = Shelf(name: trimmed, position: newPosition, isDefault: false)
            context.insert(shelf)
        }
        do { try context.save(); dismiss() }
        catch { context.rollback(); saveError = error.localizedDescription }
    }
}
