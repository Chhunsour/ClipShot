import XCTest
import Foundation
@testable import ClipShotCore

final class PathUtilsBookmarkTests: XCTestCase {

    func testDisplayPathForRootDirectory() {
        let rootURL = URL(fileURLWithPath: "/")
        let display = PathUtils.shared.displayPath(for: rootURL)
        XCTAssertEqual(display, "/")
    }

    func testCanReadFolderRejectsRegularFile() throws {
        let tempFile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_file_\(UUID().uuidString).txt")
        try "test".write(to: tempFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempFile) }

        // canReadFolder requires the path to be a directory, not a file
        XCTAssertFalse(PathUtils.shared.canReadFolder(at: tempFile))
    }

    func testCanReadFolderAcceptsTemporaryDirectory() {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        XCTAssertTrue(PathUtils.shared.canReadFolder(at: tempDir))
    }

    func testTildeExpansionPreservesAbsolutePath() {
        let path = "/Library/Application Support"
        let expanded = (path as NSString).expandingTildeInPath
        XCTAssertEqual(expanded, path)
    }
}
