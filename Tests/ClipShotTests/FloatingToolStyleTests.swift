import XCTest
import CoreGraphics
@testable import ClipShotCore

final class FloatingToolStyleTests: XCTestCase {

    func testFloatingToolStyleCasesAndTitles() {
        XCTAssertEqual(FloatingToolStyle.button.rawValue, "button")
        XCTAssertEqual(FloatingToolStyle.button.title, "Compact Button")

        XCTAssertEqual(FloatingToolStyle.expanded.rawValue, "expanded")
        XCTAssertEqual(FloatingToolStyle.expanded.title, "Expanded Dock")

        XCTAssertEqual(FloatingToolStyle.hidden.rawValue, "hidden")
        XCTAssertEqual(FloatingToolStyle.hidden.title, "Hidden")
    }

    func testFloatingToolStyleCodableRoundtrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for style in FloatingToolStyle.allCases {
            let data = try encoder.encode(style)
            let decoded = try decoder.decode(FloatingToolStyle.self, from: data)
            XCTAssertEqual(decoded, style)
        }
    }

    func testWindowInfoDisplayNameFormatting() {
        let fullWindow = WindowInfo(
            id: 101,
            windowName: "Document.pdf",
            ownerName: "Preview",
            bounds: CGRect(x: 0, y: 0, width: 800, height: 600),
            windowLayer: 0
        )
        XCTAssertEqual(fullWindow.displayName, "Preview — Document.pdf")

        let appOnlyWindow = WindowInfo(
            id: 102,
            windowName: "",
            ownerName: "Finder",
            bounds: CGRect(x: 100, y: 100, width: 600, height: 400),
            windowLayer: 0
        )
        XCTAssertEqual(appOnlyWindow.displayName, "Finder")

        let anonymousWindow = WindowInfo(
            id: 999,
            windowName: "",
            ownerName: "",
            bounds: .zero,
            windowLayer: 0
        )
        XCTAssertEqual(anonymousWindow.displayName, "Window #999")
    }
}
