import XCTest
@testable import ClipShotCore

final class CaptureModeTests: XCTestCase {

    func testCaptureModeRawValues() {
        XCTAssertEqual(CaptureMode.area.rawValue, "area")
        XCTAssertEqual(CaptureMode.window.rawValue, "window")
        XCTAssertEqual(CaptureMode.screen.rawValue, "screen")
        XCTAssertEqual(CaptureMode.scrolling.rawValue, "scrolling")
        XCTAssertEqual(CaptureMode.ocr.rawValue, "ocr")
        XCTAssertEqual(CaptureMode.record.rawValue, "record")
        XCTAssertEqual(CaptureMode.colorPicker.rawValue, "color_picker")
        XCTAssertEqual(CaptureMode.measure.rawValue, "measure")
    }

    func testCaptureModeTitles() {
        XCTAssertEqual(CaptureMode.area.title, "Area")
        XCTAssertEqual(CaptureMode.window.title, "Window")
        XCTAssertEqual(CaptureMode.screen.title, "Screen")
        XCTAssertEqual(CaptureMode.scrolling.title, "Scroll")
        XCTAssertEqual(CaptureMode.ocr.title, "OCR")
        XCTAssertEqual(CaptureMode.record.title, "Record")
        XCTAssertEqual(CaptureMode.colorPicker.title, "Color")
        XCTAssertEqual(CaptureMode.measure.title, "Measure")
    }

    func testCaptureModeIcons() {
        XCTAssertEqual(CaptureMode.area.iconName, "crop")
        XCTAssertEqual(CaptureMode.window.iconName, "rectangle.inset.filled")
        XCTAssertEqual(CaptureMode.screen.iconName, "macwindow")
        XCTAssertEqual(CaptureMode.scrolling.iconName, "arrow.down.doc")
        XCTAssertEqual(CaptureMode.ocr.iconName, "text.viewfinder")
        XCTAssertEqual(CaptureMode.record.iconName, "record.circle")
        XCTAssertEqual(CaptureMode.colorPicker.iconName, "eyedropper")
        XCTAssertEqual(CaptureMode.measure.iconName, "ruler")
    }

    func testCaptureModeCodableRoundtrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for mode in CaptureMode.allCases {
            let data = try encoder.encode(mode)
            let decoded = try decoder.decode(CaptureMode.self, from: data)
            XCTAssertEqual(decoded, mode)
        }
    }
}
