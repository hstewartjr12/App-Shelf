import SwiftUI
import WidgetKit

struct CurrentlyTrackingWidgetView: View {
    var entry: WidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .accessoryRectangular:
            rectangularView
        default:
            smallView
        }
    }

    // MARK: - Small: single featured item

    private var smallView: some View {
        ZStack(alignment: .bottomLeading) {
            if let item = entry.items.first, let data = item.coverImageData,
               let img = PlatformImage.from(data: data) {
                #if os(iOS)
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                #endif
            } else {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.6), Color.accentColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                if let item = entry.items.first {
                    Image(systemName: item.mediaType.systemImage)
                        .font(.largeTitle)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.shelfName)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                Text(entry.items.first?.title ?? "Nothing here")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.black.opacity(0.4))
        }
        .containerBackground(for: .widget) {
            Color.black
        }
    }

    // MARK: - Medium: 2-3 items in a row

    private var mediumView: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.shelfName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                if entry.items.isEmpty {
                    Text("Nothing here yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.leading)
            .frame(maxHeight: .infinity, alignment: .topLeading)

            Spacer()

            HStack(spacing: 8) {
                ForEach(entry.items.prefix(3)) { item in
                    WidgetCoverView(item: item, size: CGSize(width: 72, height: 100))
                }
            }
            .padding(.trailing, 12)
            .padding(.vertical, 10)
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    // MARK: - Lock screen rectangular: text only

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.shelfName)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(entry.items.first?.title ?? "Nothing on this shelf")
                .font(.headline)
                .lineLimit(1)
            if entry.items.count > 1 {
                Text("+ \(entry.items.count - 1) more")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { Color.clear }
    }
}

struct WidgetCoverView: View {
    let item: WidgetMediaItem
    let size: CGSize

    var body: some View {
        VStack(spacing: 4) {
            Group {
                if let data = item.coverImageData, let img = PlatformImage.from(data: data) {
                    #if os(iOS)
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                    #endif
                } else {
                    LinearGradient(
                        colors: [placeholderColor.opacity(0.6), placeholderColor],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .overlay(
                        Image(systemName: item.mediaType.systemImage)
                            .foregroundStyle(.white.opacity(0.7))
                    )
                }
            }
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(item.title)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: size.width)
        }
    }

    private var placeholderColor: Color {
        switch item.mediaType {
        case .game: return .purple
        case .show: return .blue
        case .movie: return .red
        case .book: return .green
        case .music: return .pink
        case .other: return .orange
        }
    }
}
