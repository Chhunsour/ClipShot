import AppKit
import XCTest
@testable import ClipShotCore

final class ColorFormatHSLMathTests: XCTestCase {
    func testPurePrimaryColorsHSL() {
        let service = ColorPickerService.shared

        // Pure Red
        let red = NSColor(srgbRed: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        let redHSL = service.hslString(from: red)
        XCTAssertTrue(redHSL == "hsl(0°, 100%, 100%)" || redHSL == "hsl(360°, 100%, 100%)")

        // Pure Green
        let green = NSColor(srgbRed: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
        let greenHSL = service.hslString(from: green)
        XCTAssertEqual(greenHSL, "hsl(120°, 100%, 100%)")

        // Pure Blue
        let blue = NSColor(srgbRed: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
        let blueHSL = service.hslString(from: blue)
        XCTAssertEqual(blueHSL, "hsl(240°, 100%, 100%)")
    }

    func testMonochromeShadesHaveZeroSaturation() {
        let service = ColorPickerService.shared

        let black = NSColor(srgbRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        XCTAssertEqual(service.hslString(from: black), "hsl(0°, 0%, 0%)")

        let white = NSColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        XCTAssertEqual(service.hslString(from: white), "hsl(0°, 0%, 100%)")

        let midGray = NSColor(srgbRed: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        XCTAssertEqual(service.hslString(from: midGray), "hsl(0°, 0%, 50%)")
    }

    func testDisplayP3FormatPattern() {
        let service = ColorPickerService.shared
        let orange = NSColor(srgbRed: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)
        let p3String = service.displayP3String(from: orange)

        XCTAssertTrue(p3String.hasPrefix("color(display-p3 "))
        XCTAssertTrue(p3String.hasSuffix(")"))

        let components = p3String
            .replacingOccurrences(of: "color(display-p3 ", with: "")
            .replacingOccurrences(of: ")", with: "")
            .split(separator: " ")
            .compactMap { Double($0) }

        XCTAssertEqual(components.count, 3)
        for c in components {
            XCTAssertGreaterThanOrEqual(c, 0.0)
            XCTAssertLessThanOrEqual(c, 1.05) // Allow small gamut headroom
        }
    }

    func testRGBHexEquivalence() {
        let service = ColorPickerService.shared
        let color = NSColor(srgbRed: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)

        let hex = service.hexString(from: color)
        let rgb = service.rgbString(from: color)

        // Parse hex to decimal
        let scanner = Scanner(string: String(hex.dropFirst()))
        var hexNumber: UInt64 = 0
        XCTAssertTrue(scanner.scanHexInt64(&hexNumber))

        let rHex = Int((hexNumber & 0xFF0000) >> 16)
        let gHex = Int((hexNumber & 0x00FF00) >> 8)
        let bHex = Int(hexNumber & 0x0000FF)

        XCTAssertEqual(rgb, "rgb(\(rHex), \(gHex), \(bHex))")
    }
}
