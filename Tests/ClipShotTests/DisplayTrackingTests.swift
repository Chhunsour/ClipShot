import XCTest
import AppKit
import CoreGraphics
@testable import ClipShotCore

@MainActor
final class DisplayTrackingTests: XCTestCase {

    func testDisplayIdentifierModel() {
        let display = DisplayIdentifier(
            id: "uuid-1234",
            name: "Portable Monitor",
            directDisplayID: 1,
            frame: CGRect(x: 1920, y: 0, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 1920, y: 0, width: 1920, height: 1055),
            scaleFactor: 2.0,
            isMain: false
        )

        XCTAssertEqual(display.id, "uuid-1234")
        XCTAssertEqual(display.name, "Portable Monitor")
        XCTAssertEqual(display.resolutionString, "3840 × 2160")
        XCTAssertTrue(display.displayName.contains("Portable Monitor"))
    }

    func testDisplayIdentifierMainDisplayFormatting() {
        let display = DisplayIdentifier(
            id: "main-screen",
            name: "Built-in Retina Display",
            directDisplayID: 0,
            frame: CGRect(x: 0, y: 0, width: 1728, height: 1117),
            visibleFrame: CGRect(x: 0, y: 0, width: 1728, height: 1085),
            scaleFactor: 2.0,
            isMain: true
        )
        XCTAssertEqual(display.displayName, "Built-in Retina Display (Main Display)")
    }

    func testDisplayIdentifierCodableRoundTrip() throws {
        let original = DisplayIdentifier(
            id: "disp-99",
            name: "Studio Display",
            directDisplayID: 42,
            frame: CGRect(x: 0, y: 0, width: 2560, height: 1440),
            visibleFrame: CGRect(x: 0, y: 0, width: 2560, height: 1400),
            scaleFactor: 2.0,
            isMain: false
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DisplayIdentifier.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testNotchOriginCalculationTopHeader() {
        let service = DisplayTrackingService.shared
        let size = CGSize(width: 100, height: 32)

        let settings = AppSettings.shared
        settings.clipNotchPlacementMode = .topHeader
        settings.clipNotchVerticalOffset = 0.0

        let origin = service.computeNotchOrigin(for: size, settings: settings)

        XCTAssertFalse(origin.x.isNaN)
        XCTAssertFalse(origin.y.isNaN)

        if let screen = service.activeNSScreen() {
            let expectedX = screen.frame.midX - (size.width / 2.0)
            let expectedY = screen.frame.maxY - size.height
            XCTAssertEqual(origin.x, expectedX, accuracy: 0.1)
            XCTAssertEqual(origin.y, expectedY, accuracy: 0.1)
        }
    }

    func testNotchOriginCalculationFloatingIsland() {
        let service = DisplayTrackingService.shared
        let size = CGSize(width: 100, height: 32)

        let settings = AppSettings.shared
        settings.clipNotchPlacementMode = .floatingIsland
        settings.clipNotchVerticalOffset = 0.0

        let origin = service.computeNotchOrigin(for: size, settings: settings)

        if let screen = service.activeNSScreen() {
            let expectedY = screen.frame.maxY - size.height - 6.0
            XCTAssertEqual(origin.y, expectedY, accuracy: 0.1)
        }
    }
}
