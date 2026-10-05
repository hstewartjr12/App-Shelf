import SwiftUI

enum ShelfStyle {
    static let ink = Color(red: 0.10, green: 0.24, blue: 0.23)
    static let sage = Color(red: 0.25, green: 0.47, blue: 0.40)
    // Foreground colors adapt independently of cover/chip fills, which keep their white text.
    static let sageForeground = Color.shelfAdaptive(
        light: (0.25, 0.47, 0.40), dark: (0.57, 0.77, 0.66)
    )
    static let gold = Color(red: 0.78, green: 0.56, blue: 0.28)
    static let goldForeground = Color.shelfAdaptive(
        light: (0.59, 0.39, 0.14), dark: (0.91, 0.74, 0.48)
    )
    static let canvas = Color.shelfCanvas
}

extension Color {
    static func shelfAdaptive(light: (Double, Double, Double), dark: (Double, Double, Double)) -> Color {
        #if os(iOS)
        Color(uiColor: UIColor { traits in
            let values = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: values.0, green: values.1, blue: values.2, alpha: 1)
        })
        #else
        Color(nsColor: NSColor(name: nil) { appearance in
            let values = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
            return NSColor(srgbRed: values.0, green: values.1, blue: values.2, alpha: 1)
        })
        #endif
    }

    static var shelfCanvas: Color {
        #if os(iOS)
        Color(uiColor: .systemGroupedBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }

    static var shelfCard: Color {
        #if os(iOS)
        Color(uiColor: .secondarySystemGroupedBackground)
        #else
        Color(nsColor: .controlBackgroundColor)
        #endif
    }
}

extension MediaType {
    var foregroundColor: Color {
        switch self {
        case .game: return .shelfAdaptive(light: (0.43, 0.35, 0.65), dark: (0.73, 0.65, 0.90))
        case .show: return .shelfAdaptive(light: (0.28, 0.45, 0.60), dark: (0.57, 0.75, 0.90))
        case .movie: return .shelfAdaptive(light: (0.66, 0.35, 0.30), dark: (0.93, 0.64, 0.58))
        case .book: return ShelfStyle.sageForeground
        case .music: return .shelfAdaptive(light: (0.64, 0.37, 0.49), dark: (0.89, 0.65, 0.76))
        case .other: return ShelfStyle.goldForeground
        }
    }

    var color: Color {
        switch self {
        case .game: return Color(red: 0.43, green: 0.35, blue: 0.65)
        case .show: return Color(red: 0.28, green: 0.45, blue: 0.60)
        case .movie: return Color(red: 0.66, green: 0.35, blue: 0.30)
        case .book: return ShelfStyle.sage
        case .music: return Color(red: 0.64, green: 0.37, blue: 0.49)
        case .other: return ShelfStyle.gold
        }
    }
}

struct ShelfErrorModifier: ViewModifier {
    @Binding var message: String?
    func body(content: Content) -> some View {
        content.alert("Couldn’t save your changes", isPresented: Binding(
            get: { message != nil }, set: { if !$0 { message = nil } }
        )) {
            Button("OK", role: .cancel) { message = nil }
        } message: {
            Text(message ?? "Please try again.")
        }
    }
}

extension View {
    func shelfSaveAlert(_ message: Binding<String?>) -> some View {
        modifier(ShelfErrorModifier(message: message))
    }
}
