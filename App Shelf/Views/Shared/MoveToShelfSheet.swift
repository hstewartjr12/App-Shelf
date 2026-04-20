import SwiftUI
import SwiftData

struct MoveToShelfSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Shelf.position) private var shelves: [Shelf]

    let item: MediaItem

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
        .presentationDetents([.medium])
    }

    private func move(to shelf: Shelf) {
        guard item.move(to: shelf) else {
            dismiss()
            return
        }

        try? context.save()
        dismiss()
    }
}
