import Foundation
import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum ImageCompression {
    static let maxDimension: CGFloat = 600
    static let jpegQuality: CGFloat = 0.72

    /// Resize and JPEG-compress image data to a reasonable size for storage.
    static func compress(_ data: Data) -> Data? {
        guard let image = PlatformImage.from(data: data) else { return nil }
        #if os(iOS)
        let resized = resize(image, maxDimension: maxDimension)
        return resized.jpegData(quality: jpegQuality)
        #elseif os(macOS)
        let resized = image.resized(toMaxDimension: maxDimension)
        return resized.jpegData(quality: jpegQuality)
        #endif
    }

    #if os(iOS)
    private static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let w = image.size.width, h = image.size.height
        guard w > maxDimension || h > maxDimension else { return image }
        let scale = maxDimension / max(w, h)
        let newSize = CGSize(width: w * scale, height: h * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    #endif
}
