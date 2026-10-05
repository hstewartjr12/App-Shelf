import SwiftUI
import SwiftData

struct MoveToShelfSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Shelf.position) private var shelves: [Shelf]

    let item: MediaItem
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            List {
                ForEach(shelves) { shelf in
                    Button {
                        move(to: shelf)
                    } label: {
                        HStack {
                            Text(shelf.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if item.shelf?.persistentModelID == shelf.persistentModelID {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Move to Shelf")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .shelfSaveAlert($saveError)
        #if os(macOS)
        .frame(minWidth: 320, minHeight: 280)
        #else
        .presentationDetents([.medium])
        #endif
    }

    private func move(to shelf: Shelf) {
        guard item.move(to: shelf) else {
            dismiss()
            return
        }

        do { try context.save(); dismiss() }
        catch { context.rollback(); saveError = error.localizedDescription }
    }
}
