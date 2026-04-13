import SwiftUI
import SwiftData

struct ShelfRowView: View {
    @Environment(\.modelContext) private var context
    let shelf: Shelf

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(shelf.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                Spacer()
                Text("\(shelf.items.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }

            if shelf.sortedItems.isEmpty {
                EmptyStateView(
                    systemImage: "plus.circle.dashed",
                    title: "Nothing here yet",
                    subtitle: "Tap + to add something"
                )
                .frame(height: 140)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(shelf.sortedItems) { item in
                            VStack(spacing: 6) {
                                CoverCardView(item: item)
                                Text(item.title)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 100)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}
