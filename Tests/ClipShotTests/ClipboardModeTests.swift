import XCTest
@testable import ClipShotCore

final class ClipboardModeTests: XCTestCase {

    func testAllCasesExist() {
        XCTAssertEqual(ClipboardMode.allCases.count, 3)
    }

    func testTitlesAreDescriptive() {
        XCTAssertEqual(ClipboardMode.imageOnly.title, "Image only")
        XCTAssertEqual(ClipboardMode.imageAndFile.title, "Image + file reference")
        XCTAssertEqual(ClipboardMode.fileOnly.title, "File reference only")
    }

    func testRawValuesMatchIdentifiers() {
        XCTAssertEqual(ClipboardMode.imageOnly.rawValue, "image_only")
        XCTAssertEqual(ClipboardMode.imageAndFile.rawValue, "image_and_file")
        XCTAssertEqual(ClipboardMode.fileOnly.rawValue, "file_only")
    }
}
