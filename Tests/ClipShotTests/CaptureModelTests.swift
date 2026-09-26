import XCTest
import AppKit
@testable import ClipShotCore

final class CaptureModelTests: XCTestCase {

    func testCaptureModeCasesAndMetadata() {
        XCTAssertEqual(CaptureMode.allCases.count, 8)
        for mode in CaptureMode.allCases {
            XCTAssertEqual(mode.id, mode.rawValue)
            XCTAssertFalse(mode.title.isEmpty)
            XCTAssertFalse(mode.iconName.isEmpty)
        }
    }

    func testColorFormatCases() {
        let expected: [ColorFormat] = [.hex, .rgb, .hsl, .displayP3]
        XCTAssertEqual(ColorFormat.allCases, expected)
        for format in ColorFormat.allCases {
            XCTAssertEqual(format.id, format.rawValue)
        }
    }

    func testResizeHandleCases() {
        XCTAssertEqual(ResizeHandle.allCases.count, 8)
        let handles: [ResizeHandle] = [
            .topLeft, .top, .topRight,
            .left, .right,
            .bottomLeft, .bottom, .bottomRight
        ]
        XCTAssertEqual(ResizeHandle.allCases, handles)
    }

    func testFloatingToolStyleCasesAndTitles() {
        XCTAssertEqual(FloatingToolStyle.allCases.count, 3)
        for style in FloatingToolStyle.allCases {
            XCTAssertEqual(style.id, style.rawValue)
            XCTAssertFalse(style.title.isEmpty)
        }
    }
}
