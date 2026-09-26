import XCTest
import AppKit
import CoreGraphics
@testable import ClipShotCore

final class ScrollingCaptureServiceTests: XCTestCase {

    private func createTestCGImage(width: Int, height: Int, color: NSColor) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.setFillColor(color.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return ctx.makeImage()
    }

    func testStitchEmptyFramesReturnsNil() {
        let service = ScrollingCaptureService()
        XCTAssertNil(service.stitchFrames([]))
    }

    func testStitchSingleFrameReturnsImage() {
        let service = ScrollingCaptureService()
        guard let frame = createTestCGImage(width: 200, height: 150, color: .blue) else {
            XCTFail("Failed to create test CGImage")
            return
        }

        let stitched = service.stitchFrames([frame])
        XCTAssertNotNil(stitched)
        XCTAssertEqual(stitched?.size.width, 200)
        XCTAssertEqual(stitched?.size.height, 150)
    }

    func testStitchMultipleFramesIncreasesHeight() {
        let service = ScrollingCaptureService()
        guard let frame1 = createTestCGImage(width: 200, height: 100, color: .red),
              let frame2 = createTestCGImage(width: 200, height: 100, color: .green) else {
            XCTFail("Failed to create test CGImages")
            return
        }

        guard let stitched = service.stitchFrames([frame1, frame2]) else {
            XCTFail("Expected stitched image")
            return
        }

        XCTAssertEqual(stitched.size.width, 200)
        XCTAssertGreaterThan(stitched.size.height, 100)
    }
}
