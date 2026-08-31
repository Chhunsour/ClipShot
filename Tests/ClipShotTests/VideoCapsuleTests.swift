import XCTest
import CoreGraphics
@testable import ClipShotCore

final class VideoCapsuleTests: XCTestCase {

    func testVideoCapsuleModelCreation() {
        let model = VideoCapsuleModel(
            windowID: 42,
            appName: "QuickTime Player",
            windowTitle: "Demo Video.mp4",
            cropRect: CGRect(x: 0, y: 0, width: 640, height: 360),
            scalingMode: .fill,
            targetFPS: 60
        )

        XCTAssertEqual(model.windowID, 42)
        XCTAssertEqual(model.appName, "QuickTime Player")
        XCTAssertEqual(model.scalingMode, .fill)
        XCTAssertEqual(model.targetFPS, 60)
        XCTAssertEqual(model.displayTitle, "QuickTime Player — Demo Video.mp4")
    }

    func testVideoCapsuleDimensions() {
        XCTAssertEqual(VideoCapsuleSize.small.dimensions.width, 280)
        XCTAssertEqual(VideoCapsuleSize.medium.dimensions.width, 360)
        XCTAssertEqual(VideoCapsuleSize.large.dimensions.width, 480)
    }
}
