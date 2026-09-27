import AppKit
import CoreGraphics
import XCTest
@testable import ClipShotCore

final class VideoCapsuleAspectCalculationTests: XCTestCase {
    func testCapsuleSizeAspectRatiosAreWidescreen() {
        for size in VideoCapsuleSize.allCases {
            let dimensions = size.dimensions
            XCTAssertGreaterThan(dimensions.width, dimensions.height, "\(size.rawValue) should have width greater than height")
            let ratio = dimensions.width / dimensions.height
            // Standard 16:9 is approximately 1.7778
            XCTAssertEqual(ratio, 1.77, accuracy: 0.05, "\(size.rawValue) aspect ratio should approximate 16:9")
        }
    }

    func testVideoScalingModeIdentifiersAndCases() {
        XCTAssertEqual(VideoScalingMode.allCases.count, 3)
        XCTAssertEqual(VideoScalingMode.fit.rawValue, "Fit")
        XCTAssertEqual(VideoScalingMode.fill.rawValue, "Fill")
        XCTAssertEqual(VideoScalingMode.original.rawValue, "16:9")
        for mode in VideoScalingMode.allCases {
            XCTAssertEqual(mode.id, mode.rawValue)
        }
    }

    func testAspectFitCalculationMath() {
        let container = CGSize(width: 360, height: 203)
        let sourceUltraWide = CGSize(width: 2560, height: 1080) // ~21:9

        let scaleX = container.width / sourceUltraWide.width
        let scaleY = container.height / sourceUltraWide.height
        let fitScale = min(scaleX, scaleY)

        let fittedSize = CGSize(width: sourceUltraWide.width * fitScale, height: sourceUltraWide.height * fitScale)
        XCTAssertEqual(fittedSize.width, container.width, accuracy: 0.1)
        XCTAssertLessThanOrEqual(fittedSize.height, container.height)

        let sourceTall = CGSize(width: 1080, height: 1920) // 9:16 portrait
        let tallScaleX = container.width / sourceTall.width
        let tallScaleY = container.height / sourceTall.height
        let tallFitScale = min(tallScaleX, tallScaleY)

        let tallFittedSize = CGSize(width: sourceTall.width * tallFitScale, height: sourceTall.height * tallFitScale)
        XCTAssertEqual(tallFittedSize.height, container.height, accuracy: 0.1)
        XCTAssertLessThanOrEqual(tallFittedSize.width, container.width)
    }

    func testAspectFillCalculationMath() {
        let container = CGSize(width: 360, height: 203)
        let sourceTall = CGSize(width: 1080, height: 1920) // 9:16 portrait

        let scaleX = container.width / sourceTall.width
        let scaleY = container.height / sourceTall.height
        let fillScale = max(scaleX, scaleY)

        let filledSize = CGSize(width: sourceTall.width * fillScale, height: sourceTall.height * fillScale)
        XCTAssertEqual(filledSize.width, container.width, accuracy: 0.1)
        XCTAssertGreaterThanOrEqual(filledSize.height, container.height)
    }

    func testVideoCapsuleModelCropRectAndMutation() {
        let windowID: CGWindowID = 42
        var model = VideoCapsuleModel(
            windowID: windowID,
            appName: "Safari",
            windowTitle: "GitHub — Pull Requests",
            cropRect: CGRect(x: 10, y: 20, width: 800, height: 600),
            scalingMode: .fit,
            targetFPS: 60,
            isPoppedOut: false
        )

        XCTAssertEqual(model.cropRect, CGRect(x: 10, y: 20, width: 800, height: 600))
        XCTAssertFalse(model.isPoppedOut)
        XCTAssertEqual(model.targetFPS, 60)

        // Mutate properties
        model.scalingMode = .fill
        model.isPoppedOut = true
        model.cropRect = nil

        XCTAssertEqual(model.scalingMode, .fill)
        XCTAssertTrue(model.isPoppedOut)
        XCTAssertNil(model.cropRect)
    }
}
