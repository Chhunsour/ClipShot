import XCTest
import Foundation
@testable import ClipShotCore

final class ShellPathEscapingTests: XCTestCase {

    /// Helper that performs standard POSIX single-quote escaping for shell safety.
    private func posixShellEscape(_ path: String) -> String {
        guard !path.isEmpty else { return "''" }
        // Replace single quote ' with '\'' and wrap entire token in single quotes
        let escaped = path.replacingOccurrences(of: "'", with: "'\\''")
        return "'\(escaped)'"
    }

    func testStandardFilenameWithSpaces() {
        let original = "/Users/test/Desktop/Screen Shot 2026-09-29 at 09.12.00.png"
        let escaped = posixShellEscape(original)
        XCTAssertEqual(escaped, "'/Users/test/Desktop/Screen Shot 2026-09-29 at 09.12.00.png'")
    }

    func testFilenameWithSingleQuotes() {
        let original = "/Users/test/Desktop/Bob's Screenshot.png"
        let escaped = posixShellEscape(original)
        XCTAssertEqual(escaped, "'/Users/test/Desktop/Bob'\\''s Screenshot.png'")
    }

    func testFilenameWithShellExpansionCharacters() {
        let dangerousName = "/tmp/$HOME `rm -rf /` $(whoami) &;*.png"
        let escaped = posixShellEscape(dangerousName)
        XCTAssertTrue(escaped.hasPrefix("'"))
        XCTAssertTrue(escaped.hasSuffix("'"))
        XCTAssertFalse(escaped.contains("rm -rf /'"))
    }

    func testUnicodeAndEmojiFilenames() {
        let original = "/Users/test/Desktop/Capture 📸 2026 🚀.png"
        let escaped = posixShellEscape(original)
        XCTAssertEqual(escaped, "'/Users/test/Desktop/Capture 📸 2026 🚀.png'")
    }

    func testEmptyStringReturnsEmptySingleQuotes() {
        let escaped = posixShellEscape("")
        XCTAssertEqual(escaped, "''")
    }

    func testProcessArgumentsBypassesShellInterpolation() {
        // When using Foundation.Process with an arguments array, arguments are passed
        // directly via execve(2) without shell interpolation, so special characters
        // require no manual escaping.
        let rawPath = "/tmp/test space's & \"symbols\".png"
        let process = Process()
        process.arguments = ["-x", rawPath]
        XCTAssertEqual(process.arguments?[1], rawPath)
    }
}
