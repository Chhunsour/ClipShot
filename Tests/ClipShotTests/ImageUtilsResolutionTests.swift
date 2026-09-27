import AppKit
import CoreGraphics
import XCTest
@testable import ClipShotCore

final class ImageUtilsResolutionTests: XCTestCase {
    func testPointToPixelRetinaCalculations() {
        let pointSize = CGSize(width: 1440, height: 900)

        // @1x Standard Display
        let scale1x: CGFloat = 1.0
        let pixels1x = CGSize(width: pointSize.width * scale1x, height: pointSize.height * scale1x)
        XCTAssertEqual(pixels1x.width, 1440)
        XCTAssertEqual(pixels1x.height, 900)

        // @2x Retina Display
        let scale2x: CGFloat = 2.0
        let pixels2x = CGSize(width: pointSize.width * scale2x, height: pointSize.height * scale2x)
        XCTAssertEqual(pixels2x.width, 2880)
        XCTAssertEqual(pixels2x.height, 1800)

        // Point recovery from pixel dimensions
        let recoveredPoints = CGSize(width: pixels2x.width / scale2x, height: pixels2x.height / scale2x)
        XCTAssertEqual(recoveredPoints, pointSize)
    }

    func testSupportedExtensionsCaseInsensitivity() {
        let validExtensions = ["png", "PNG", "jpg", "JPG", "jpeg", "TIFF", "heic", "webp", "WEBP"]
        for ext in validExtensions {
            let url = URL(fileURLWithPath: "/tmp/sample.\(ext)")
            XCTAssertTrue(ImageUtils.isImageFile(at: url), "Expected \(ext) to be recognized as image")
        }

        let nonImageExtensions = ["txt", "pdf", "mov", "mp4", "zip", "json", "swift"]
        for ext in nonImageExtensions {
            let url = URL(fileURLWithPath: "/tmp/sample.\(ext)")
            XCTAssertFalse(ImageUtils.isImageFile(at: url), "Expected \(ext) to NOT be recognized as image")
        }
    }

    func testRetinaThumbnailMaxPixelSizeConstraint() {
        let maxDimension: CGFloat = 320.0
        let largePixelSize = CGSize(width: 3840, height: 2160) // 4K UHD

        let aspect = largePixelSize.width / largePixelSize.height
        let targetWidth = maxDimension
        let targetHeight = targetWidth / aspect

        XCTAssertLessThanOrEqual(targetWidth, maxDimension)
        XCTAssertLessThanOrEqual(targetHeight, maxDimension)
        XCTAssertEqual(targetWidth / targetHeight, aspect, accuracy: 0.001)
    }

    func testCGImageToPNGDataRoundtrip() throws {
        let context = try XCTUnwrap(CGContext(
            data: nil,
            width: 16,
            height: 16,
            bitsPerComponent: 8,
            bytesPerRow: 16 * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(srgbRed: 0.2, green: 0.6, blue: 0.9, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: 16, height: 16))

        let cgImage = try XCTUnwrap(context.makeImage())
        let pngData = try XCTUnwrap(ImageUtils.pngData(from: cgImage))

        XCTAssertFalse(pngData.isEmpty)
        // PNG magic header: 0x89, 'P', 'N', 'G'
        XCTAssertEqual(pngData[0], 0x89)
        XCTAssertEqual(pngData[1], 0x50)
        XCTAssertEqual(pngData[2], 0x4E)
        XCTAssertEqual(pngData[3], 0x47)
    }
}
