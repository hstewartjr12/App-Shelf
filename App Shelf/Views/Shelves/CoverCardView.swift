import SwiftUI
import SwiftData

struct CoverCardView: View {
    @Environment(\.modelContext) private var context
    let item: MediaItem
    @State private var showMoveSheet = false
    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            CoverImageView(
                data: item.coverImageData,
                mediaType: item.mediaType,
                cornerRadius: 12,
                size: CGSize(width: 100, height: 140)
            )
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                showMoveSheet = true
            } label: {
                Label("Move to Shelf", systemImage: "tray.and.arrow.up")
            }

            Divider()

            Button(role: .destructive) {
                context.delete(item)
                try? context.save()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showMoveSheet) {
            MoveToShelfSheet(item: item)
        }
        .sheet(isPresented: $showDetail) {
            ItemDetailView(item: item)
        }
    }
}
