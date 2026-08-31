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
