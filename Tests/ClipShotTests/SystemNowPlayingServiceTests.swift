import XCTest
@testable import ClipShotCore

final class SystemNowPlayingServiceTests: XCTestCase {
    func testSystemMediaSnapshotDecoding() throws {
        let data = #"{"title":"Video","artist":"Creator","artworkBase64":"AQID","isPlaying":true}"#.data(using: .utf8)!
        let snapshot = try JSONDecoder().decode(SystemMediaSnapshot.self, from: data)
        XCTAssertEqual(snapshot.title, "Video")
        XCTAssertEqual(snapshot.artist, "Creator")
        XCTAssertEqual(snapshot.artworkBase64, "AQID")
        XCTAssertTrue(snapshot.isPlaying)
    }
}
