import XCTest
import Foundation
@testable import ClipShotCore

final class PathUtilsTests: XCTestCase {

    func testDisplayPathReplacesHomeDirectoryWithTilde() {
        let home = NSHomeDirectory()
        let desktopURL = URL(fileURLWithPath: "\(home)/Desktop/Screenshots")
        let display = PathUtils.shared.displayPath(for: desktopURL)

        XCTAssertEqual(display, "~/Desktop/Screenshots")
    }

    func testDisplayPathPreservesNonHomePaths() {
        let systemURL = URL(fileURLWithPath: "/System/Library/CoreServices")
        let display = PathUtils.shared.displayPath(for: systemURL)

        XCTAssertEqual(display, "/System/Library/CoreServices")
    }

    func testActiveScreenshotFolderReturnsValidDirectory() {
        let folder = PathUtils.shared.activeScreenshotFolder()

        XCTAssertTrue(FileManager.default.fileExists(atPath: folder.path))
        XCTAssertTrue(PathUtils.shared.canReadFolder(at: folder))
    }

    func testCanReadFolderRejectsNonExistentDirectory() {
        let fakeURL = URL(fileURLWithPath: "/tmp/non_existent_folder_\(UUID().uuidString)")

        XCTAssertFalse(PathUtils.shared.canReadFolder(at: fakeURL))
    }
}
