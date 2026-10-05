import SwiftUI
import SwiftData

struct CoverCardView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Shelf.position) private var shelves: [Shelf]
    let item: MediaItem
    var size: CGSize = CGSize(width: 100, height: 140)
    @State private var showMoveSheet = false
    @State private var showDetail = false
    @State private var confirmDelete = false
    @State private var saveError: String?

    var body: some View {
        Button { showDetail = true } label: {
            CoverImageView(data: item.coverImageData, mediaType: item.mediaType,
                           title: item.title, cornerRadius: 13, size: size)
                .shadow(color: .black.opacity(0.12), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open \(item.title), \(item.mediaType.displayName), \(item.shelf?.name ?? "no shelf")")
        .contextMenu {
            Button { showDetail = true } label: { Label("Edit details", systemImage: "pencil") }
            Button { showMoveSheet = true } label: { Label("Move to shelf", systemImage: "tray.and.arrow.up") }
            Button { item.isFavorite.toggle(); save() } label: {
                Label(item.isFavorite ? "Remove favorite" : "Favorite", systemImage: item.isFavorite ? "heart.slash" : "heart")
            }
            if item.finishedDate == nil, let finished = shelves.first(where: \.isFinishedShelf) {
                Button { item.move(to: finished); save() } label: {
                    Label("Mark finished", systemImage: "checkmark.seal")
                }
            }
            Divider()
            Button(role: .destructive) { confirmDelete = true } label: { Label("Delete", systemImage: "trash") }
        }
        .confirmationDialog("Delete \(item.title)?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete item", role: .destructive) {
                item.shelf?.normalizeItemPositions(removing: item)
                context.delete(item)
                save()
            }
        } message: { Text("Its notes, cover, and progress will also be removed.") }
        .sheet(isPresented: $showMoveSheet) { MoveToShelfSheet(item: item) }
        .sheet(isPresented: $showDetail) { ItemDetailView(item: item) }
        .shelfSaveAlert($saveError)
    }

    private func save() {
        do { try context.save() }
        catch { context.rollback(); saveError = error.localizedDescription }
    }
}
