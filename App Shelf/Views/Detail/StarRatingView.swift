import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Int?
    var maxRating = 5
    var starSize: CGFloat = 28

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { star in
                Image(systemName: starImage(for: star))
                    .font(.system(size: starSize))
                    .foregroundStyle(starColor(for: star))
                    .onTapGesture {
                        if rating == star {
                            rating = nil
                        } else {
                            rating = star
                        }
                    }
            }
        }
        .animation(.spring(response: 0.2), value: rating)
    }

    private func starImage(for star: Int) -> String {
        (rating ?? 0) >= star ? "star.fill" : "star"
    }

    private func starColor(for star: Int) -> Color {
        (rating ?? 0) >= star ? .yellow : .secondary.opacity(0.4)
    }
}
