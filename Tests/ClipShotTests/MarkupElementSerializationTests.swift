import XCTest
import CoreGraphics
import SwiftUI
@testable import ClipShotCore

final class MarkupElementSerializationTests: XCTestCase {

    struct CodableMarkupData: Codable, Equatable {
        let toolRaw: String
        let startX: Double
        let startY: Double
        let endX: Double
        let endY: Double
        let strokeWidth: Double
        let text: String
    }

    func testMarkupToolRawValueParsing() {
        XCTAssertEqual(MarkupTool(rawValue: "Arrow"), .arrow)
        XCTAssertEqual(MarkupTool(rawValue: "Step"), .step)
        XCTAssertEqual(MarkupTool(rawValue: "Blur"), .blur)
        XCTAssertNil(MarkupTool(rawValue: "InvalidToolName"))
    }

    func testCodableMarkupElementRoundtrip() throws {
        let original = CodableMarkupData(
            toolRaw: MarkupTool.rectangle.rawValue,
            startX: 100.5,
            startY: 200.0,
            endX: 450.2,
            endY: 600.8,
            strokeWidth: 4.0,
            text: "Important Area"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CodableMarkupData.self, from: data)

        XCTAssertEqual(original, decoded)
        XCTAssertEqual(MarkupTool(rawValue: decoded.toolRaw), .rectangle)
    }

    func testStepAutoNumberingSequence() {
        var elements: [MarkupElement] = []
        for i in 1...5 {
            elements.append(
                MarkupElement(
                    tool: .step,
                    startPoint: CGPoint(x: i * 20, y: i * 20),
                    endPoint: CGPoint(x: i * 20, y: i * 20),
                    points: [],
                    color: .blue,
                    strokeWidth: 2.0,
                    text: "\(i)"
                )
            )
        }

        let stepTexts = elements.filter { $0.tool == .step }.map(\.text)
        XCTAssertEqual(stepTexts, ["1", "2", "3", "4", "5"])
    }
}
