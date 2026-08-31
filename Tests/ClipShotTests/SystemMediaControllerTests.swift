import XCTest
@testable import ClipShotCore

final class SystemMediaControllerTests: XCTestCase {
    func testMediaKeyEventEncoding() {
        XCTAssertEqual(
            SystemMediaController.eventData(for: .playPause, keyDown: true),
            (16 << 16) | (0xA << 8)
        )
        XCTAssertEqual(
            SystemMediaController.eventData(for: .next, keyDown: false),
            (17 << 16) | (0xB << 8)
        )
        XCTAssertEqual(SystemMediaController.mediaRemoteValue(for: .playPause), 2)
        XCTAssertEqual(SystemMediaController.mediaRemoteValue(for: .next), 4)
        XCTAssertEqual(SystemMediaController.mediaRemoteValue(for: .previous), 5)
    }
}
