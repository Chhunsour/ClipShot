import XCTest
import CoreGraphics
@testable import ClipShotCore

final class VideoCapsuleStreamModelTests: XCTestCase {

    func testUUIDUniqueness() {
        let m1 = VideoCapsuleModel(windowID: 1, appName: "App1", windowTitle: "Title1")
        let m2 = VideoCapsuleModel(windowID: 1, appName: "App1", windowTitle: "Title1")

        XCTAssertNotEqual(m1.id, m2.id)
    }

    func testIsPoppedOutState() {
        var model = VideoCapsuleModel(windowID: 10, appName: "VLC", windowTitle: "Movie", isPoppedOut: false)
        XCTAssertFalse(model.isPoppedOut)

        model.isPoppedOut = true
        XCTAssertTrue(model.isPoppedOut)
    }

    func testVideoCapsuleSizeAspectRatios() {
        for size in VideoCapsuleSize.allCases {
            let dim = size.dimensions
            let ratio = dim.width / dim.height
            // 16 / 9 ≈ 1.777
            XCTAssertEqual(ratio, 1.77, accuracy: 0.05)
        }
    }

    func testFPSClampingBounds() {
        func clampFPS(_ fps: Int) -> Int {
            return min(max(fps, 15), 60)
        }

        XCTAssertEqual(clampFPS(5), 15)
        XCTAssertEqual(clampFPS(30), 30)
        XCTAssertEqual(clampFPS(120), 60)
    }
}
