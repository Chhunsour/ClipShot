import XCTest
import AppKit
@testable import ClipShotCore

final class ColorFormatConversionExtendedTests: XCTestCase {

    func testSecondaryColorsHexConversion() {
        let service = ColorPickerService.shared

        // Yellow: R=1, G=1, B=0
        let yellow = NSColor(srgbRed: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)
        XCTAssertEqual(service.hexString(from: yellow), "#FFFF00")

        // Cyan: R=0, G=1, B=1
        let cyan = NSColor(srgbRed: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)
        XCTAssertEqual(service.hexString(from: cyan), "#00FFFF")

        // Magenta: R=1, G=0, B=1
        let magenta = NSColor(srgbRed: 1.0, green: 0.0, blue: 1.0, alpha: 1.0)
        XCTAssertEqual(service.hexString(from: magenta), "#FF00FF")
    }

    func testGrayscaleHexAndRGBConversion() {
        let service = ColorPickerService.shared
        let gray = NSColor(srgbRed: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)

        let hex = service.hexString(from: gray)
        XCTAssertEqual(hex, "#808080")

        let rgb = service.rgbString(from: gray)
        XCTAssertEqual(rgb, "rgb(128, 128, 128)")
    }

    func testColorResultStatePresentationKind() {
        let state = ClipNotchState.colorResult(hex: "#FF5500", rgb: "rgb(255, 85, 0)", hsl: "hsl(20°, 100%, 50%)")
        XCTAssertEqual(state.presentationKind, .colorResult)
    }

    func testColorFormatRawValues() {
        XCTAssertEqual(ColorFormat.hex.rawValue, "HEX")
        XCTAssertEqual(ColorFormat.rgb.rawValue, "RGB")
        XCTAssertEqual(ColorFormat.hsl.rawValue, "HSL")
        XCTAssertEqual(ColorFormat.displayP3.rawValue, "Display P3")
    }
}
