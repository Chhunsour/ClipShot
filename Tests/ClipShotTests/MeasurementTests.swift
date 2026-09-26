import XCTest
import CoreGraphics
@testable import ClipShotCore

final class MeasurementTests: XCTestCase {

    func testDistanceCalculation() {
        let service = MeasurementService.shared

        let p1 = CGPoint(x: 0, y: 0)
        let p2 = CGPoint(x: 300, y: 400)
        let dist = service.distance(from: p1, to: p2)
        XCTAssertEqual(dist, 500.0, accuracy: 0.001)
    }

    func testRectDimensionFormatting() {
        let service = MeasurementService.shared
        let rect = CGRect(x: 10, y: 20, width: 1280, height: 720)
        let formatted = service.formatRectDimensions(rect)
        XCTAssertEqual(formatted, "1280 × 720 px")
    }

    func testDistanceFormatting() {
        let service = MeasurementService.shared
        // Vertical
        let p1 = CGPoint(x: 100, y: 100)
        let p2 = CGPoint(x: 100, y: 250)
        let formattedV = service.formatDistance(from: p1, to: p2)
        XCTAssertEqual(formattedV, "150 px (V)")

        // Horizontal
        let p3 = CGPoint(x: 250, y: 100)
        let formattedH = service.formatDistance(from: p1, to: p3)
        XCTAssertEqual(formattedH, "150 px (H)")

        // Diagonal
        let p4 = CGPoint(x: 400, y: 500)
        let formattedD = service.formatDistance(from: p1, to: p4)
        XCTAssertEqual(formattedD, "500 px (Δx: 300, Δy: 400)")
    }
}
