import Foundation

/// Lightweight value type used by the widget — avoids passing @Model objects across the boundary.
struct WidgetMediaItem: Identifiable {
    let id: String
    let title: String
    let coverImageData: Data?
    let mediaType: MediaType
}
