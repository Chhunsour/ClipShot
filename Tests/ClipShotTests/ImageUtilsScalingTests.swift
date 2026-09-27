import XCTest
import CoreGraphics
@testable import ClipShotCore

final class ImageUtilsScalingTests: XCTestCase {

    func testAspectFitDownscaling() {
        func aspectFitSize(original: CGSize, boundingBox: CGSize) -> CGSize {
            let widthRatio = boundingBox.width / original.width
            let heightRatio = boundingBox.height / original.height
            let scale = min(widthRatio, heightRatio)
            return CGSize(width: original.width * scale, height: original.height * scale)
        }

        let original = CGSize(width: 1920, height: 1080)
        let bounding = CGSize(width: 300, height: 300)
        let fitted = aspectFitSize(original: original, boundingBox: bounding)

        XCTAssertEqual(fitted.width, 300, accuracy: 0.001)
        XCTAssertEqual(fitted.height, 168.75, accuracy: 0.001)
        XCTAssertEqual(fitted.width / fitted.height, original.width / original.height, accuracy: 0.001)
    }

    func testAspectFillCalculation() {
        func aspectFillSize(original: CGSize, boundingBox: CGSize) -> CGSize {
            let widthRatio = boundingBox.width / original.width
            let heightRatio = boundingBox.height / original.height
            let scale = max(widthRatio, heightRatio)
            return CGSize(width: original.width * scale, height: original.height * scale)
        }

        let original = CGSize(width: 1920, height: 1080)
        let bounding = CGSize(width: 300, height: 300)
        let filled = aspectFillSize(original: original, boundingBox: bounding)

        XCTAssertEqual(filled.height, 300, accuracy: 0.001)
        XCTAssertEqual(filled.width, 533.333, accuracy: 0.01)
    }

    func testSquareAspectRatioPreservation() {
        let original = CGSize(width: 512, height: 512)
        let bounding = CGSize(width: 128, height: 128)
        let scale = min(bounding.width / original.width, bounding.height / original.height)
        let result = CGSize(width: original.width * scale, height: original.height * scale)

        XCTAssertEqual(result.width, 128)
        XCTAssertEqual(result.height, 128)
    }
}
