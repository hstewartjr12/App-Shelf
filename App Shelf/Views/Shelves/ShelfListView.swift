import SwiftUI
import SwiftData

struct ShelfListView: View {
    @Query(sort: \Shelf.position) private var shelves: [Shelf]
    @State private var showAddItem = false

    var body: some View {
        NavigationStack {
            Group {
                if shelves.isEmpty {
                    EmptyStateView(
                        systemImage: "books.vertical",
                        title: "No shelves yet",
                        subtitle: "Your shelves will appear here"
                    )
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 28) {
                            ForEach(shelves) { shelf in
                                ShelfRowView(shelf: shelf)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("My Shelf")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddItem) {
                AddItemSheet()
            }
        }
    }
}
