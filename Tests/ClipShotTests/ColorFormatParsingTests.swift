import XCTest
import AppKit
@testable import ClipShotCore

final class ColorFormatParsingTests: XCTestCase {

    func testAllCasesAndOrder() {
        let cases = ColorFormat.allCases
        XCTAssertEqual(cases.count, 4)
        XCTAssertEqual(cases, [.hex, .rgb, .hsl, .displayP3])
    }

    func testRawValuesAndIDs() {
        XCTAssertEqual(ColorFormat.hex.rawValue, "HEX")
        XCTAssertEqual(ColorFormat.rgb.rawValue, "RGB")
        XCTAssertEqual(ColorFormat.hsl.rawValue, "HSL")
        XCTAssertEqual(ColorFormat.displayP3.rawValue, "Display P3")

        for format in ColorFormat.allCases {
            XCTAssertEqual(format.id, format.rawValue)
        }
    }

    func testCodableRoundtrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for original in ColorFormat.allCases {
            let data = try encoder.encode(original)
            let decoded = try decoder.decode(ColorFormat.self, from: data)
            XCTAssertEqual(decoded, original)
        }
    }

    func testInvalidRawValueReturnsNil() {
        XCTAssertNil(ColorFormat(rawValue: "CMYK"))
        XCTAssertNil(ColorFormat(rawValue: "hex"))
        XCTAssertNil(ColorFormat(rawValue: ""))
    }

    func testHexFormattingWithPureColors() {
        let service = ColorPickerService.shared
        let red = NSColor(srgbRed: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        let green = NSColor(srgbRed: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
        let blue = NSColor(srgbRed: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
        let white = NSColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        let black = NSColor(srgbRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)

        XCTAssertEqual(service.hexString(from: red), "#FF0000")
        XCTAssertEqual(service.hexString(from: green), "#00FF00")
        XCTAssertEqual(service.hexString(from: blue), "#0000FF")
        XCTAssertEqual(service.hexString(from: white), "#FFFFFF")
        XCTAssertEqual(service.hexString(from: black), "#000000")
    }

    func testRGBFormattingWithPureColors() {
        let service = ColorPickerService.shared
        let red = NSColor(srgbRed: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        let white = NSColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

        XCTAssertEqual(service.rgbString(from: red), "rgb(255, 0, 0)")
        XCTAssertEqual(service.rgbString(from: white), "rgb(255, 255, 255)")
    }

    func testDisplayP3FormattingSyntax() {
        let service = ColorPickerService.shared
        let p3Red = NSColor(displayP3Red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        let formatted = service.displayP3String(from: p3Red)
        XCTAssertTrue(formatted.hasPrefix("color(display-p3 "))
        XCTAssertTrue(formatted.contains("1.000"))
        XCTAssertTrue(formatted.hasSuffix(")"))
    }
}
