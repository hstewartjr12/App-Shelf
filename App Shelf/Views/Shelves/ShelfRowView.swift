import SwiftUI
import SwiftData

struct ShelfRowView: View {
    let shelf: Shelf

    #if os(macOS)
    private let cardSize = CGSize(width: 120, height: 168)
    private let emptyStateHeight: CGFloat = 120
    #else
    private let cardSize = CGSize(width: 100, height: 140)
    private let emptyStateHeight: CGFloat = 140
    #endif

    var body: some View {
        let items = shelf.sortedItems

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

            if items.isEmpty {
                EmptyStateView(
                    systemImage: "plus.circle.dashed",
                    title: "Nothing here yet",
                    subtitle: "Use + to add something"
                )
                .frame(height: emptyStateHeight)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(items) { item in
                            VStack(spacing: 6) {
                                CoverCardView(item: item, size: cardSize)
                                Text(item.title)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(width: cardSize.width)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}
