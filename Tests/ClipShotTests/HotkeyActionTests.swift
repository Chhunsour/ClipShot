import XCTest
@testable import ClipShotCore

final class HotkeyActionTests: XCTestCase {

    func testHotkeyActionAllCases() {
        XCTAssertEqual(HotkeyAction.allCases.count, 10)
    }

    func testHotkeyActionIdentifiers() {
        XCTAssertEqual(HotkeyAction.captureOverlay.rawValue, "capture_overlay")
        XCTAssertEqual(HotkeyAction.captureArea.rawValue, "capture_area")
        XCTAssertEqual(HotkeyAction.captureScreen.rawValue, "capture_screen")
        XCTAssertEqual(HotkeyAction.captureWindow.rawValue, "capture_window")
        XCTAssertEqual(HotkeyAction.commandPalette.rawValue, "command_palette")
        XCTAssertEqual(HotkeyAction.openHistory.rawValue, "open_history")
    }

    func testTitlesAreDescriptive() {
        for action in HotkeyAction.allCases {
            XCTAssertFalse(action.title.isEmpty)
            XCTAssertEqual(action.id, action.rawValue)
        }
    }

    func testHotkeyActionCodableRoundTrip() throws {
        for action in HotkeyAction.allCases {
            let data = try JSONEncoder().encode(action)
            let decoded = try JSONDecoder().decode(HotkeyAction.self, from: data)
            XCTAssertEqual(action, decoded)
        }
    }
}
