import Foundation
import XCTest
@testable import ClipShotCore

final class ClipboardTextDetectionTests: XCTestCase {
    struct ClipboardTextFormatter {
        static func formatSingleLine(from raw: String?) -> String {
            guard let text = raw else { return "" }
            let singleLine = text
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            return singleLine.isEmpty ? "Empty" : singleLine
        }

        static func tooltip(for text: String?, isImage: Bool, isCopied: Bool) -> String {
            if isCopied { return "Restored to clipboard" }
            if isImage { return "Image (Click to copy)" }

            let display = formatSingleLine(from: text)
            let prefix = display.prefix(60)
            return prefix.count < display.count ? "\(prefix)... (Click to copy)" : "\(display) (Click to copy)"
        }
    }

    func testMultiLineCollapseToSingleLine() {
        let multiLine = "Line 1\nLine 2\r\nLine 3"
        let formatted = ClipboardTextFormatter.formatSingleLine(from: multiLine)
        XCTAssertEqual(formatted, "Line 1 Line 2 Line 3")
    }

    func testWhitespaceTrimmingAndEmptyLineFilter() {
        let messy = "   Hello   \n\n\t   World   \n  "
        let formatted = ClipboardTextFormatter.formatSingleLine(from: messy)
        XCTAssertEqual(formatted, "Hello World")
    }

    func testOnlyWhitespaceYieldsEmptyFallback() {
        let whitespaceOnly = "   \n\t  \r\n   "
        let formatted = ClipboardTextFormatter.formatSingleLine(from: whitespaceOnly)
        XCTAssertEqual(formatted, "Empty")

        XCTAssertEqual(ClipboardTextFormatter.formatSingleLine(from: nil), "")
    }

    func testTooltipTextShortTextDoesNotTruncate() {
        let short = "Short snippet"
        let tip = ClipboardTextFormatter.tooltip(for: short, isImage: false, isCopied: false)
        XCTAssertEqual(tip, "Short snippet (Click to copy)")
    }

    func testTooltipTextLongTextTruncatesAtSixtyWithEllipsis() {
        let long = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore."
        let tip = ClipboardTextFormatter.tooltip(for: long, isImage: false, isCopied: false)
        XCTAssertTrue(tip.hasSuffix("... (Click to copy)"))
        XCTAssertTrue(tip.hasPrefix("Lorem ipsum dolor sit amet"))
        XCTAssertEqual(tip.prefix(60), long.prefix(60))
    }

    func testTooltipImageAndCopiedStates() {
        let imgTip = ClipboardTextFormatter.tooltip(for: nil, isImage: true, isCopied: false)
        XCTAssertEqual(imgTip, "Image (Click to copy)")

        let copiedTip = ClipboardTextFormatter.tooltip(for: "Copied text", isImage: false, isCopied: true)
        XCTAssertEqual(copiedTip, "Restored to clipboard")
    }
}
