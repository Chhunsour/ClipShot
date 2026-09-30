import XCTest
import CoreGraphics
@testable import ClipShotCore

final class ResizeHandleGeometryTests: XCTestCase {

    func testAllCasesCountAndOrder() {
        let handles = ResizeHandle.allCases
        XCTAssertEqual(handles.count, 8)
        XCTAssertEqual(handles, [
            .topLeft, .top, .topRight,
            .left, .right,
            .bottomLeft, .bottom, .bottomRight
        ])
    }

    func testHandleAnchorPointsCalculation() {
        let rect = CGRect(x: 100, y: 100, width: 400, height: 300)

        func anchor(for handle: ResizeHandle) -> CGPoint {
            switch handle {
            case .topLeft: return CGPoint(x: rect.minX, y: rect.minY)
            case .top: return CGPoint(x: rect.midX, y: rect.minY)
            case .topRight: return CGPoint(x: rect.maxX, y: rect.minY)
            case .left: return CGPoint(x: rect.minX, y: rect.midY)
            case .right: return CGPoint(x: rect.maxX, y: rect.midY)
            case .bottomLeft: return CGPoint(x: rect.minX, y: rect.maxY)
            case .bottom: return CGPoint(x: rect.midX, y: rect.maxY)
            case .bottomRight: return CGPoint(x: rect.maxX, y: rect.maxY)
            }
        }

        XCTAssertEqual(anchor(for: .topLeft), CGPoint(x: 100, y: 100))
        XCTAssertEqual(anchor(for: .top), CGPoint(x: 300, y: 100))
        XCTAssertEqual(anchor(for: .topRight), CGPoint(x: 500, y: 100))
        XCTAssertEqual(anchor(for: .left), CGPoint(x: 100, y: 250))
        XCTAssertEqual(anchor(for: .right), CGPoint(x: 500, y: 250))
        XCTAssertEqual(anchor(for: .bottomLeft), CGPoint(x: 100, y: 400))
        XCTAssertEqual(anchor(for: .bottom), CGPoint(x: 300, y: 400))
        XCTAssertEqual(anchor(for: .bottomRight), CGPoint(x: 500, y: 400))
    }

    func testHandleDragDeltaCalculations() {
        var rect = CGRect(x: 100, y: 100, width: 400, height: 300)
        let delta = CGPoint(x: 50, y: 30)

        // Dragging right handle expands width
        rect.size.width += delta.x
        XCTAssertEqual(rect.width, 450)

        // Dragging bottom handle expands height
        rect.size.height += delta.y
        XCTAssertEqual(rect.height, 330)

        // Dragging left handle moves origin and decreases width
        rect.origin.x += 20
        rect.size.width -= 20
        XCTAssertEqual(rect.origin.x, 120)
        XCTAssertEqual(rect.width, 430)
    }

    func testOppositeHandlesRelationship() {
        func opposite(of handle: ResizeHandle) -> ResizeHandle {
            switch handle {
            case .topLeft: return .bottomRight
            case .top: return .bottom
            case .topRight: return .bottomLeft
            case .left: return .right
            case .right: return .left
            case .bottomLeft: return .topRight
            case .bottom: return .top
            case .bottomRight: return .topLeft
            }
        }

        for handle in ResizeHandle.allCases {
            XCTAssertEqual(opposite(of: opposite(of: handle)), handle)
        }
    }
}
