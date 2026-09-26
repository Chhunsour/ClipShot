import XCTest
import SwiftUI
@testable import ClipShotCore

final class MarkupToolTests: XCTestCase {

    func testMarkupToolAllCases() {
        XCTAssertEqual(MarkupTool.allCases.count, 10)
        let expected: [MarkupTool] = [
            .arrow, .line, .rectangle, .ellipse, .step,
            .pen, .text, .highlight, .blur, .pixelate
        ]
        XCTAssertEqual(MarkupTool.allCases, expected)
    }

    func testMarkupToolMetadata() {
        for tool in MarkupTool.allCases {
            XCTAssertEqual(tool.id, tool.rawValue)
            XCTAssertFalse(tool.iconName.isEmpty)
        }
    }

    func testMarkupElementInitialization() {
        let element = MarkupElement(
            tool: .arrow,
            startPoint: CGPoint(x: 10, y: 10),
            endPoint: CGPoint(x: 50, y: 50),
            points: [CGPoint(x: 10, y: 10), CGPoint(x: 50, y: 50)],
            color: .red,
            strokeWidth: 3.0,
            text: "Annotation"
        )
        XCTAssertEqual(element.tool, .arrow)
        XCTAssertEqual(element.startPoint, CGPoint(x: 10, y: 10))
        XCTAssertEqual(element.endPoint, CGPoint(x: 50, y: 50))
        XCTAssertEqual(element.strokeWidth, 3.0)
        XCTAssertEqual(element.text, "Annotation")
    }
}
