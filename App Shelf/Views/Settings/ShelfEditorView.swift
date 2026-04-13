import SwiftUI
import SwiftData

struct ShelfEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Shelf.position) private var shelves: [Shelf]

    var editingShelf: Shelf?
    @State private var name: String

    init(editing shelf: Shelf? = nil) {
        self.editingShelf = shelf
        _name = State(initialValue: shelf?.name ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Shelf name", text: $name)
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
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(200)])
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let shelf = editingShelf {
            shelf.name = trimmed
        } else {
            let newPosition = (shelves.map(\.position).max() ?? -1) + 1
            let shelf = Shelf(name: trimmed, position: newPosition, isDefault: false)
            context.insert(shelf)
        }
        try? context.save()
        dismiss()
    }
}
