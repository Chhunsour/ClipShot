import AppKit
import CoreGraphics
import XCTest
@testable import ClipShotCore

final class ScreenGeometryNudgeTests: XCTestCase {
    struct NudgeCalculator {
        static func offset(for keyCode: UInt16, isShiftPressed: Bool) -> (dx: CGFloat, dy: CGFloat)? {
            let step: CGFloat = isShiftPressed ? 10 : 1
            switch keyCode {
            case 123: // Left
                return (-step, 0)
            case 124: // Right
                return (step, 0)
            case 125: // Down
                return (0, step)
            case 126: // Up
                return (0, -step)
            default:
                return nil
            }
        }

        static func applyNudge(to rect: CGRect, dx: CGFloat, dy: CGFloat, clampedTo bounds: CGRect? = nil) -> CGRect {
            var nudged = rect
            nudged.origin.x += dx
            nudged.origin.y += dy

            guard let bounds = bounds else { return nudged }

            nudged.origin.x = max(bounds.minX, min(nudged.origin.x, bounds.maxX - nudged.width))
            nudged.origin.y = max(bounds.minY, min(nudged.origin.y, bounds.maxY - nudged.height))
            return nudged
        }

        static func normalizeRect(from start: CGPoint, to current: CGPoint) -> CGRect {
            let x = min(start.x, current.x)
            let y = min(start.y, current.y)
            let width = abs(current.x - start.x)
            let height = abs(current.y - start.y)
            return CGRect(x: x, y: y, width: width, height: height)
        }
    }

    func testArrowKeyNudgeOffsetsSinglePixel() {
        XCTAssertEqual(NudgeCalculator.offset(for: 123, isShiftPressed: false)?.dx, -1)
        XCTAssertEqual(NudgeCalculator.offset(for: 123, isShiftPressed: false)?.dy, 0)

        XCTAssertEqual(NudgeCalculator.offset(for: 124, isShiftPressed: false)?.dx, 1)
        XCTAssertEqual(NudgeCalculator.offset(for: 124, isShiftPressed: false)?.dy, 0)

        XCTAssertEqual(NudgeCalculator.offset(for: 125, isShiftPressed: false)?.dx, 0)
        XCTAssertEqual(NudgeCalculator.offset(for: 125, isShiftPressed: false)?.dy, 1)

        XCTAssertEqual(NudgeCalculator.offset(for: 126, isShiftPressed: false)?.dx, 0)
        XCTAssertEqual(NudgeCalculator.offset(for: 126, isShiftPressed: false)?.dy, -1)
    }

    func testArrowKeyNudgeOffsetsWithShiftTenPixels() {
        XCTAssertEqual(NudgeCalculator.offset(for: 123, isShiftPressed: true)?.dx, -10)
        XCTAssertEqual(NudgeCalculator.offset(for: 124, isShiftPressed: true)?.dx, 10)
        XCTAssertEqual(NudgeCalculator.offset(for: 125, isShiftPressed: true)?.dy, 10)
        XCTAssertEqual(NudgeCalculator.offset(for: 126, isShiftPressed: true)?.dy, -10)
    }

    func testNudgeAppliesToSelectionRect() {
        let initial = CGRect(x: 100, y: 100, width: 200, height: 150)
        let nudged = NudgeCalculator.applyNudge(to: initial, dx: 1, dy: -1)

        XCTAssertEqual(nudged.origin.x, 101)
        XCTAssertEqual(nudged.origin.y, 99)
        XCTAssertEqual(nudged.size.width, 200)
        XCTAssertEqual(nudged.size.height, 150)
    }

    func testNudgeClampedWithinDisplayBounds() {
        let displayBounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let edgeRect = CGRect(x: 1900, y: 10, width: 20, height: 20)

        // Attempting to nudge +10 right should be clamped so rect.maxX <= 1920
        let clampedRight = NudgeCalculator.applyNudge(to: edgeRect, dx: 10, dy: 0, clampedTo: displayBounds)
        XCTAssertEqual(clampedRight.maxX, 1920)

        // Attempting to nudge -20 up should be clamped so rect.minY >= 0
        let clampedTop = NudgeCalculator.applyNudge(to: edgeRect, dx: 0, dy: -20, clampedTo: displayBounds)
        XCTAssertEqual(clampedTop.minY, 0)
    }

    func testNormalizedRectAlwaysHasPositiveDimensions() {
        // Dragging top-left to bottom-right
        let normal = NudgeCalculator.normalizeRect(from: CGPoint(x: 50, y: 50), to: CGPoint(x: 150, y: 200))
        XCTAssertEqual(normal, CGRect(x: 50, y: 50, width: 100, height: 150))

        // Dragging bottom-right to top-left (negative drag)
        let reversed = NudgeCalculator.normalizeRect(from: CGPoint(x: 150, y: 200), to: CGPoint(x: 50, y: 50))
        XCTAssertEqual(reversed, CGRect(x: 50, y: 50, width: 100, height: 150))
    }
}
