import XCTest
import SwiftUI
@testable import ClipShotCore

final class AnnotationTests: XCTestCase {

    func testMarkupToolIconNames() {
        for tool in MarkupTool.allCases {
            XCTAssertFalse(tool.iconName.isEmpty)
            XCTAssertFalse(tool.rawValue.isEmpty)
        }
    }

    func testMarkupElementCreation() {
        let el = MarkupElement(
            tool: .step,
            startPoint: CGPoint(x: 50, y: 50),
            endPoint: CGPoint(x: 50, y: 50),
            points: [],
            color: .red,
            strokeWidth: 4.0,
            text: "1"
        )

        XCTAssertEqual(el.tool, .step)
        XCTAssertEqual(el.text, "1")
        XCTAssertEqual(el.strokeWidth, 4.0)
    }
}
