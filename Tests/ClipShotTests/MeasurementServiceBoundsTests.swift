import XCTest
import CoreGraphics
@testable import ClipShotCore

final class MeasurementServiceBoundsTests: XCTestCase {

    func testZeroDistanceAndIdenticalPoints() {
        let service = MeasurementService()
        let origin = CGPoint(x: 500, y: 500)
        
        let dist = service.distance(from: origin, to: origin)
        XCTAssertEqual(dist, 0.0, accuracy: 0.0001)
        
        // When dx == 0, formatDistance returns vertical format
        let formatted = service.formatDistance(from: origin, to: origin)
        XCTAssertEqual(formatted, "0 px (V)")
    }

    func testNegativeCoordinatesMultiMonitorSpan() {
        let service = MeasurementService()
        // Primary screen (0, 0) to secondary screen positioned leftwards (-1920, 0)
        let primaryScreenPoint = CGPoint(x: 0, y: 500)
        let secondaryScreenPoint = CGPoint(x: -1920, y: 500)

        let dist = service.distance(from: primaryScreenPoint, to: secondaryScreenPoint)
        XCTAssertEqual(dist, 1920.0, accuracy: 0.001)

        let formatted = service.formatDistance(from: primaryScreenPoint, to: secondaryScreenPoint)
        XCTAssertEqual(formatted, "1920 px (H)")
    }

    func testInvertedRectDimensionsWithNegativeWidthAndHeight() {
        let service = MeasurementService()
        // Dragging top-leftwards results in negative width and height
        let invertedRect = CGRect(x: 800, y: 600, width: -350.2, height: -200.7)
        let formatted = service.formatRectDimensions(invertedRect)
        XCTAssertEqual(formatted, "350 × 201 px")
    }

    func testSubpixelRoundingBehavior() {
        let service = MeasurementService()
        let p1 = CGPoint(x: 10.2, y: 20.4)
        let p2 = CGPoint(x: 10.2, y: 70.8) // dy = 50.4, rounded to 50

        let formatted = service.formatDistance(from: p1, to: p2)
        XCTAssertEqual(formatted, "50 px (V)")

        let rect = CGRect(x: 0, y: 0, width: 99.4, height: 99.6)
        XCTAssertEqual(service.formatRectDimensions(rect), "99 × 100 px")
    }

    func testDistanceCalculationSymmetry() {
        let service = MeasurementService()
        let pA = CGPoint(x: -240.5, y: 810.0)
        let pB = CGPoint(x: 1440.0, y: -120.3)

        let distAB = service.distance(from: pA, to: pB)
        let distBA = service.distance(from: pB, to: pA)
        XCTAssertEqual(distAB, distBA, accuracy: 0.0001)
    }

    func testLargeResolutionMultiDisplaySpan() {
        let service = MeasurementService()
        // Dual 5K (5120x2880) arrangement spanning 10240x2880
        let p1 = CGPoint(x: 0, y: 0)
        let p2 = CGPoint(x: 10240, y: 2880)

        let dist = service.distance(from: p1, to: p2)
        let expectedDist = sqrt(pow(10240.0, 2) + pow(2880.0, 2))
        XCTAssertEqual(dist, expectedDist, accuracy: 0.01)

        let formatted = service.formatDistance(from: p1, to: p2)
        XCTAssertTrue(formatted.contains("Δx: 10240"))
        XCTAssertTrue(formatted.contains("Δy: 2880"))
    }
}
