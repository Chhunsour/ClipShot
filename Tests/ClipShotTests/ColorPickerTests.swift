import XCTest
import AppKit
@testable import ClipShotCore

final class ColorPickerTests: XCTestCase {

    func testHexStringFormatting() {
        let service = ColorPickerService.shared

        let redColor = NSColor(srgbRed: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        XCTAssertEqual(service.hexString(from: redColor), "#FF0000")

        let greenColor = NSColor(srgbRed: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
        XCTAssertEqual(service.hexString(from: greenColor), "#00FF00")

        let blueColor = NSColor(srgbRed: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
        XCTAssertEqual(service.hexString(from: blueColor), "#0000FF")
    }

    func testRGBStringFormatting() {
        let service = ColorPickerService.shared
        let whiteColor = NSColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        XCTAssertEqual(service.rgbString(from: whiteColor), "rgb(255, 255, 255)")

        let blackColor = NSColor(srgbRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        XCTAssertEqual(service.rgbString(from: blackColor), "rgb(0, 0, 0)")
    }

    func testRecentColorManagement() {
        let settings = AppSettings.shared
        settings.addRecentColor("#123456")
        XCTAssertTrue(settings.recentColors.contains("#123456"))
        XCTAssertEqual(settings.recentColors.first, "#123456")
    }
}
