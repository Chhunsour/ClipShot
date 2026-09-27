import XCTest
import CoreGraphics
@testable import ClipShotCore

final class MeasurementSnappingTests: XCTestCase {

    func testDistanceToSelfIsZero() {
        let service = MeasurementService.shared
        let point = CGPoint(x: 245.5, y: 189.2)
        XCTAssertEqual(service.distance(from: point, to: point), 0.0, accuracy: 0.0001)
    }

    func testNegativeCoordinatesDistance() {
        let service = MeasurementService.shared
        let p1 = CGPoint(x: -50, y: -50)
        let p2 = CGPoint(x: 50, y: 50)
        let dist = service.distance(from: p1, to: p2)
        // sqrt(100^2 + 100^2) = 100 * sqrt(2) ≈ 141.421
        XCTAssertEqual(dist, 141.421, accuracy: 0.01)
    }

    func testNegativeWidthAndHeightRectFormatting() {
        let service = MeasurementService.shared
        let rect = CGRect(x: 100, y: 100, width: -640, height: -480)
        let formatted = service.formatRectDimensions(rect)
        XCTAssertEqual(formatted, "640 × 480 px")
    }

    func testAxisSnappingLogic() {
        // Test threshold-based alignment helper for measurement guides
        func snapToAxis(start: CGPoint, current: CGPoint, threshold: CGFloat = 5.0) -> CGPoint {
            var snapped = current
            if abs(current.x - start.x) <= threshold {
                snapped.x = start.x
            }
            if abs(current.y - start.y) <= threshold {
                snapped.y = start.y
            }
            return snapped
        }

        let origin = CGPoint(x: 200, y: 300)
        let nearVertical = CGPoint(x: 203, y: 450)
        let snappedV = snapToAxis(start: origin, current: nearVertical)
        XCTAssertEqual(snappedV.x, 200)
        XCTAssertEqual(snappedV.y, 450)

        let farPoint = CGPoint(x: 220, y: 450)
        let notSnapped = snapToAxis(start: origin, current: farPoint)
        XCTAssertEqual(notSnapped.x, 220)
    }
}
