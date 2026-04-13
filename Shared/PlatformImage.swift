import SwiftUI

#if os(iOS)
import UIKit
typealias PlatformImage = UIImage

extension PlatformImage {
    static func from(data: Data) -> PlatformImage? {
        PlatformImage(data: data)
    }

    func jpegData(quality: CGFloat) -> Data? {
        self.jpegData(compressionQuality: quality)
    }
}
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage

extension PlatformImage {
    static func from(data: Data) -> PlatformImage? {
        PlatformImage(data: data)
    }

    func jpegData(quality: CGFloat) -> Data? {
        guard let tiff = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(
            using: .jpeg,
            properties: [.compressionFactor: quality]
        )
    }

    // Resize to max dimension while preserving aspect ratio
    func resized(toMaxDimension maxDim: CGFloat) -> PlatformImage {
        let w = size.width, h = size.height
        guard w > maxDim || h > maxDim else { return self }
        let scale = maxDim / max(w, h)
        let newSize = NSSize(width: w * scale, height: h * scale)
        let result = NSImage(size: newSize)
        result.lockFocus()
        draw(in: NSRect(origin: .zero, size: newSize))
        result.unlockFocus()
        return result
    }
}
#endif
