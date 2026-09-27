import XCTest
@testable import ClipShotCore

final class OCRResultWindowModelTests: XCTestCase {

    func testOCRResultPresentationKind() {
        let state = ClipNotchState.ocrResult(text: "Recognized sample text")
        XCTAssertEqual(state.presentationKind, .ocrResult)
    }

    func testWordCountCalculation() {
        let text = "   Hello   world \n this is   ClipShot   "
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        XCTAssertEqual(words.count, 5)
        XCTAssertEqual(words, ["Hello", "world", "this", "is", "ClipShot"])
    }

    func testEmptyWordCount() {
        let text = "   \n\t   \n  "
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        XCTAssertEqual(words.count, 0)
    }

    func testUnicodeCharacterCount() {
        let text = "ClipShot 📸 123"
        XCTAssertEqual(text.count, 14)
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        XCTAssertEqual(words.count, 3)
    }
}
