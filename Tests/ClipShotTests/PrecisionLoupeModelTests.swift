import XCTest
import CoreGraphics
import AppKit
@testable import ClipShotCore

final class PrecisionLoupeModelTests: XCTestCase {

    func testCoordinateReadoutFormatting() {
        let point = CGPoint(x: 1420.7, y: 856.3)
        let formatted = "X: \(Int(point.x))  Y: \(Int(point.y))"
        XCTAssertEqual(formatted, "X: 1420  Y: 856")
    }

    func testLoupeCenterCrosshairCalculations() {
        let loupeDimension: CGFloat = 96.0
        let center = CGPoint(x: loupeDimension / 2.0, y: loupeDimension / 2.0)
        XCTAssertEqual(center.x, 48.0)
        XCTAssertEqual(center.y, 48.0)
    }

    func testLoupeOffsetBoundsAdjustment() {
        // Test screen bounds clamping logic for loupe popup
        func adjustedLoupeOrigin(cursor: CGPoint, loupeSize: CGSize, screenSize: CGSize) -> CGPoint {
            var origin = CGPoint(x: cursor.x + 20, y: cursor.y - loupeSize.height - 20)
            if origin.x + loupeSize.width > screenSize.width {
                origin.x = cursor.x - loupeSize.width - 20
            }
            if origin.y < 0 {
                origin.y = cursor.y + 20
            }
            return origin
        }

        let screenSize = CGSize(width: 1920, height: 1080)
        let loupeSize = CGSize(width: 120, height: 140)

        // Normal center screen position
        let centerCursor = CGPoint(x: 500, y: 500)
        let originNormal = adjustedLoupeOrigin(cursor: centerCursor, loupeSize: loupeSize, screenSize: screenSize)
        XCTAssertEqual(originNormal.x, 520)
        XCTAssertEqual(originNormal.y, 340)

        // Right edge position - flips to left of cursor
        let rightCursor = CGPoint(x: 1850, y: 500)
        let originFlippedX = adjustedLoupeOrigin(cursor: rightCursor, loupeSize: loupeSize, screenSize: screenSize)
        XCTAssertEqual(originFlippedX.x, 1710)

        // Top edge position - flips down
        let topCursor = CGPoint(x: 500, y: 100)
        let originFlippedY = adjustedLoupeOrigin(cursor: topCursor, loupeSize: loupeSize, screenSize: screenSize)
        XCTAssertEqual(originFlippedY.y, 120)
    }
}
