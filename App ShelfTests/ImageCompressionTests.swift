import Testing
import UIKit
@testable import App_Shelf

@Suite("ImageCompression")
struct ImageCompressionTests {

    @Test("compress returns nil for invalid data")
    func compressInvalidData() {
        let garbage = Data([0x00, 0x01, 0x02, 0x03])
        #expect(ImageCompression.compress(garbage) == nil)
    }

    @Test("compress returns non-nil for a valid image")
    func compressValidImage() {
        let data = makeImageData(size: CGSize(width: 100, height: 100))
        let result = ImageCompression.compress(data)
        #expect(result != nil)
    }

    @Test("compressed output is valid JPEG")
    func compressedOutputIsJPEG() throws {
        let data = makeImageData(size: CGSize(width: 200, height: 200))
        let result = try #require(ImageCompression.compress(data))
        let image = UIImage(data: result)
        #expect(image != nil)
    }

    @Test("large image is resized to within maxDimension")
    func largeImageResized() throws {
        let largeSize = CGSize(width: 1200, height: 800)
        let data = makeImageData(size: largeSize)
        let result = try #require(ImageCompression.compress(data))
        let image = try #require(UIImage(data: result))

        #expect(image.size.width <= ImageCompression.maxDimension)
        #expect(image.size.height <= ImageCompression.maxDimension)
    }

    @Test("aspect ratio is preserved after compression")
    func aspectRatioPreserved() throws {
        // 3:2 ratio image larger than maxDimension
        let data = makeImageData(size: CGSize(width: 1200, height: 800))
        let result = try #require(ImageCompression.compress(data))
        let image = try #require(UIImage(data: result))

        let originalRatio = 1200.0 / 800.0
        let compressedRatio = image.size.width / image.size.height
        #expect(abs(compressedRatio - originalRatio) < 0.01)
    }

    @Test("small image is not upscaled")
    func smallImageNotUpscaled() throws {
        let smallSize = CGSize(width: 100, height: 80)
        let data = makeImageData(size: smallSize)
        let result = try #require(ImageCompression.compress(data))
        let image = try #require(UIImage(data: result))

        // Dimensions should not exceed the original small size (no upscaling)
        #expect(image.size.width <= smallSize.width + 1) // +1 for float rounding
        #expect(image.size.height <= smallSize.height + 1)
    }

    @Test("square image at exactly maxDimension is not resized")
    func exactMaxDimensionNotResized() throws {
        let exactSize = CGSize(width: 600, height: 600)
        let data = makeImageData(size: exactSize)
        let result = try #require(ImageCompression.compress(data))
        let image = try #require(UIImage(data: result))

        #expect(image.size.width <= 600)
        #expect(image.size.height <= 600)
    }

    @Test("compression reduces file size for large images")
    func compressionReducesSize() throws {
        let largeData = makeImageData(size: CGSize(width: 2000, height: 2000))
        let result = try #require(ImageCompression.compress(largeData))
        #expect(result.count < largeData.count)
    }

    @Test("maxDimension constant is 600")
    func maxDimensionConstant() {
        #expect(ImageCompression.maxDimension == 600)
    }

    @Test("jpegQuality constant is 0.72")
    func jpegQualityConstant() {
        #expect(ImageCompression.jpegQuality == 0.72)
    }

    // MARK: - Helpers

    private func makeImageData(size: CGSize, color: UIColor = .systemBlue) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        return image.pngData()!
    }
}
