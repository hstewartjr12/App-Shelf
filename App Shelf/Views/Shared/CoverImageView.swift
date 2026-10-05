import SwiftUI

struct CoverImageView: View {
    let data: Data?
    let mediaType: MediaType
    var title: String = ""
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
                    colors: [placeholderColor.opacity(0.82), placeholderColor, placeholderColor.opacity(0.72)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(alignment: .leading) {
                Rectangle().fill(.white.opacity(0.13)).frame(width: max(3, size.width * 0.035))
            }
            .overlay(
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: mediaType.systemImage)
                        .font(.system(size: size.width * (title.isEmpty ? 0.28 : 0.17)))
                        .foregroundStyle(.white.opacity(0.65))
                    if !title.isEmpty && size.width > 70 {
                        Spacer(minLength: 0)
                        Text(title)
                            .font(.system(size: max(16, size.width * 0.16), weight: .medium, design: .serif))
                            .lineLimit(4)
                            .minimumScaleFactor(0.7)
                            .foregroundStyle(.white)
                        Rectangle().fill(.white.opacity(0.4)).frame(width: size.width * 0.25, height: 1)
                        Text(mediaType.displayName.uppercased())
                            .font(.system(size: max(7, size.width * 0.06), weight: .medium))
                            .tracking(2).foregroundStyle(.white.opacity(0.6))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: title.isEmpty ? .center : .topLeading)
                .padding(size.width * 0.13)
            )
    }

    private var placeholderColor: Color {
        mediaType.color
    }
}
