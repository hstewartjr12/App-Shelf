import SwiftUI
import SwiftData

struct ShelfListView: View {
    @Query(sort: \Shelf.position) private var shelves: [Shelf]
    @State private var showAddItem = false
    @State private var showAddShelf = false

    var body: some View {
        NavigationStack {
            Group {
                if shelves.isEmpty {
                    VStack(spacing: 16) {
                        EmptyStateView(
                            systemImage: "books.vertical",
                            title: "No shelves yet",
                            subtitle: "Create a shelf to start tracking your media."
                        )

                        Button("Create Shelf") {
                            showAddShelf = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
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
                        if shelves.isEmpty {
                            showAddShelf = true
                        } else {
                            showAddItem = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddItem) {
                AddItemSheet()
            }
            .sheet(isPresented: $showAddShelf) {
                ShelfEditorView()
            }
        }
    }
}
