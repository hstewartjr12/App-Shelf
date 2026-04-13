import SwiftUI

struct CoverImageView: View {
    let data: Data?
    let mediaType: MediaType
    var cornerRadius: CGFloat = 10
    var size: CGSize = CGSize(width: 100, height: 140)

    var body: some View {
        Group {
            if let data, let image = PlatformImage.from(data: data) {
                #if os(iOS)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                #elseif os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                #endif
            } else {
                placeholderView
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [placeholderColor.opacity(0.7), placeholderColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                VStack(spacing: 6) {
                    Image(systemName: mediaType.systemImage)
                        .font(.system(size: size.width * 0.28))
                        .foregroundStyle(.white.opacity(0.9))
                }
            )
    }

    private var placeholderColor: Color {
        switch mediaType {
        case .game: return .purple
        case .show: return .blue
        case .movie: return .red
        case .book: return .green
        case .music: return .pink
        case .other: return .orange
        }
    }
}
