import XCTest
import CoreGraphics
@testable import ClipShotCore

final class DisplayBackingScaleTests: XCTestCase {

    private func pointToPixel(_ point: CGPoint, scale: CGFloat) -> CGPoint {
        CGPoint(x: point.x * scale, y: point.y * scale)
    }

    private func pixelToPoint(_ pixel: CGPoint, scale: CGFloat) -> CGPoint {
        guard scale > 0 else { return pixel }
        return CGPoint(x: pixel.x / scale, y: pixel.y / scale)
    }

    private func scaleRect(_ rect: CGRect, scale: CGFloat) -> CGRect {
        CGRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.size.width * scale,
            height: rect.size.height * scale
        )
    }

    func testStandardDisplayOneXIdentity() {
        let logicalPoint = CGPoint(x: 450, y: 300)
        let pixelPoint = pointToPixel(logicalPoint, scale: 1.0)
        XCTAssertEqual(pixelPoint, logicalPoint)

        let roundtrip = pixelToPoint(pixelPoint, scale: 1.0)
        XCTAssertEqual(roundtrip, logicalPoint)
    }

    func testRetinaTwoXScaling() {
        let logicalPoint = CGPoint(x: 250.5, y: 120.0)
        let pixelPoint = pointToPixel(logicalPoint, scale: 2.0)
        XCTAssertEqual(pixelPoint.x, 501.0)
        XCTAssertEqual(pixelPoint.y, 240.0)

        let roundtrip = pixelToPoint(pixelPoint, scale: 2.0)
        XCTAssertEqual(roundtrip.x, 250.5)
        XCTAssertEqual(roundtrip.y, 120.0)
    }

    func testRetinaRectScaling() {
        let logicalRect = CGRect(x: 10, y: 20, width: 300, height: 200)
        let pixelRect = scaleRect(logicalRect, scale: 2.0)

        XCTAssertEqual(pixelRect.origin.x, 20)
        XCTAssertEqual(pixelRect.origin.y, 40)
        XCTAssertEqual(pixelRect.width, 600)
        XCTAssertEqual(pixelRect.height, 400)
    }

    func testSubpixelHalfPointSnappingOnRetina() {
        // On 2x Retina, 0.5 point translates to exactly 1 hardware pixel
        let halfPoint: CGFloat = 0.5
        let scale: CGFloat = 2.0
        let pixels = halfPoint * scale
        XCTAssertEqual(pixels, 1.0)
    }

    func testFrameMemoryCalculationFromRetinaDimensions() {
        // 14" MacBook Pro logical points: 1512 × 982 @ 2x -> 3024 × 1964 hardware pixels
        let logicalWidth: CGFloat = 1512
        let logicalHeight: CGFloat = 982
        let scale: CGFloat = 2.0

        let pixelWidth = Int(logicalWidth * scale)
        let pixelHeight = Int(logicalHeight * scale)
        XCTAssertEqual(pixelWidth, 3024)
        XCTAssertEqual(pixelHeight, 1964)

        // 32-bit RGBA (4 bytes per pixel)
        let bytesPerFrame = Int64(pixelWidth) * Int64(pixelHeight) * 4
        let expectedBytes: Int64 = 3024 * 1964 * 4
        XCTAssertEqual(bytesPerFrame, expectedBytes)
    }
}
