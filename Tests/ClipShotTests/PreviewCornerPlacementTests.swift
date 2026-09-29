import XCTest
import CoreGraphics
@testable import ClipShotCore

final class PreviewCornerPlacementTests: XCTestCase {

    func testAllCasesAndOrder() {
        let cases = PreviewCorner.allCases
        XCTAssertEqual(cases.count, 4)
        XCTAssertEqual(cases, [.bottomRight, .bottomLeft, .topRight, .topLeft])
    }

    func testRawValuesAndIdentifiableIDs() {
        XCTAssertEqual(PreviewCorner.bottomRight.rawValue, "bottom_right")
        XCTAssertEqual(PreviewCorner.bottomLeft.rawValue, "bottom_left")
        XCTAssertEqual(PreviewCorner.topRight.rawValue, "top_right")
        XCTAssertEqual(PreviewCorner.topLeft.rawValue, "top_left")

        for corner in PreviewCorner.allCases {
            XCTAssertEqual(corner.id, corner.rawValue)
        }
    }

    func testUserFacingTitles() {
        XCTAssertEqual(PreviewCorner.bottomRight.title, "Bottom Right")
        XCTAssertEqual(PreviewCorner.bottomLeft.title, "Bottom Left")
        XCTAssertEqual(PreviewCorner.topRight.title, "Top Right")
        XCTAssertEqual(PreviewCorner.topLeft.title, "Top Left")
    }

    func testCodableRoundtrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for original in PreviewCorner.allCases {
            let data = try encoder.encode(original)
            let decoded = try decoder.decode(PreviewCorner.self, from: data)
            XCTAssertEqual(decoded, original)
        }
    }

    func testInvalidRawValueReturnsNil() {
        XCTAssertNil(PreviewCorner(rawValue: "center"))
        XCTAssertNil(PreviewCorner(rawValue: "middle_left"))
        XCTAssertNil(PreviewCorner(rawValue: ""))
    }

    func testCornerPlacementCoordinatesCalculation() {
        // AppKit global screen coordinate system (origin at bottom-left of screen)
        let screenRect = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let overlaySize = CGSize(width: 320, height: 200)
        let margin: CGFloat = 20

        func origin(for corner: PreviewCorner) -> CGPoint {
            switch corner {
            case .topLeft:
                return CGPoint(x: screenRect.minX + margin,
                               y: screenRect.maxY - margin - overlaySize.height)
            case .topRight:
                return CGPoint(x: screenRect.maxX - margin - overlaySize.width,
                               y: screenRect.maxY - margin - overlaySize.height)
            case .bottomLeft:
                return CGPoint(x: screenRect.minX + margin,
                               y: screenRect.minY + margin)
            case .bottomRight:
                return CGPoint(x: screenRect.maxX - margin - overlaySize.width,
                               y: screenRect.minY + margin)
            }
        }

        let tl = origin(for: .topLeft)
        XCTAssertEqual(tl.x, 20)
        XCTAssertEqual(tl.y, 860)

        let tr = origin(for: .topRight)
        XCTAssertEqual(tr.x, 1580)
        XCTAssertEqual(tr.y, 860)

        let bl = origin(for: .bottomLeft)
        XCTAssertEqual(bl.x, 20)
        XCTAssertEqual(bl.y, 20)

        let br = origin(for: .bottomRight)
        XCTAssertEqual(br.x, 1580)
        XCTAssertEqual(br.y, 20)
    }
}
