import XCTest
import CoreGraphics
@testable import ClipShotCore

final class DisplayTrackingGeometryTests: XCTestCase {

    func testMultiDisplayBoundingUnion() {
        let display1 = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let display2 = CGRect(x: 1920, y: 0, width: 2560, height: 1440)

        let unionRect = display1.union(display2)
        XCTAssertEqual(unionRect.origin.x, 0)
        XCTAssertEqual(unionRect.origin.y, 0)
        XCTAssertEqual(unionRect.width, 4480)
        XCTAssertEqual(unionRect.height, 1440)
    }

    func testScaleFactorResolutionStrings() {
        let standardDisplay = DisplayIdentifier(
            id: "d1",
            name: "External 1080p",
            directDisplayID: 1,
            frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1055),
            scaleFactor: 1.0,
            isMain: false
        )
        XCTAssertEqual(standardDisplay.resolutionString, "1920 × 1080")

        let retinaDisplay = DisplayIdentifier(
            id: "d2",
            name: "Built-in Retina",
            directDisplayID: 2,
            frame: CGRect(x: 0, y: 0, width: 1512, height: 982),
            visibleFrame: CGRect(x: 0, y: 0, width: 1512, height: 940),
            scaleFactor: 2.0,
            isMain: true
        )
        XCTAssertEqual(retinaDisplay.resolutionString, "3024 × 1964")
    }

    func testNotchMidXCalculation() {
        let screenWidth: CGFloat = 1728
        let pillWidth: CGFloat = 168
        let originX = (screenWidth / 2.0) - (pillWidth / 2.0)
        XCTAssertEqual(originX, 780.0)
    }
}
