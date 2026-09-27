import AppKit
import XCTest
@testable import ClipShotCore

@MainActor
final class ClipboardHistoryDeduplicationTests: XCTestCase {
    func testCapacityLimitEnforcesMaximumTwelveItems() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("clipshot-tests-capacity-\(UUID())"))
        let manager = ClipboardHistoryManager(pasteboard: pasteboard)

        for i in 1...20 {
            pasteboard.clearContents()
            pasteboard.setString("Item \(i)", forType: .string)
            manager.checkForChanges()
        }

        XCTAssertEqual(manager.items.count, 12)
        XCTAssertEqual(manager.items.first?.text, "Item 20")
        XCTAssertEqual(manager.items.last?.text, "Item 9")
    }

    func testWhitespaceOnlyTextIsIgnored() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("clipshot-tests-whitespace-\(UUID())"))
        let manager = ClipboardHistoryManager(pasteboard: pasteboard)

        pasteboard.clearContents()
        pasteboard.setString("   \n\t  \r\n   ", forType: .string)
        manager.checkForChanges()

        XCTAssertTrue(manager.items.isEmpty)
        XCTAssertNil(manager.currentItem)
    }

    func testTextExceedingMaximumLengthIsIgnored() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("clipshot-tests-length-\(UUID())"))
        let manager = ClipboardHistoryManager(pasteboard: pasteboard)

        let oversized = String(repeating: "A", count: 50_001)
        pasteboard.clearContents()
        pasteboard.setString(oversized, forType: .string)
        manager.checkForChanges()

        XCTAssertTrue(manager.items.isEmpty)
        XCTAssertNil(manager.currentItem)

        let allowed = String(repeating: "B", count: 50_000)
        pasteboard.clearContents()
        pasteboard.setString(allowed, forType: .string)
        manager.checkForChanges()

        XCTAssertEqual(manager.items.count, 1)
        XCTAssertEqual(manager.items.first?.text?.count, 50_000)
    }

    func testTransientTypeIsIgnored() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("clipshot-tests-transient-\(UUID())"))
        let manager = ClipboardHistoryManager(pasteboard: pasteboard)

        let transient = NSPasteboardItem()
        transient.setString("temp token", forType: .string)
        transient.setString("1", forType: NSPasteboard.PasteboardType("org.nspasteboard.TransientType"))
        pasteboard.clearContents()
        pasteboard.writeObjects([transient])
        manager.checkForChanges()

        XCTAssertTrue(manager.items.isEmpty)
    }

    func testClipboardHistoryItemPropertiesAndEquality() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("clipshot-tests-props-\(UUID())"))
        let manager = ClipboardHistoryManager(pasteboard: pasteboard)

        pasteboard.clearContents()
        pasteboard.setString("Hello World", forType: .string)
        manager.checkForChanges()

        pasteboard.clearContents()
        pasteboard.setString("Second Item", forType: .string)
        manager.checkForChanges()

        XCTAssertEqual(manager.items.count, 2)
        let item1 = manager.items[0]
        let item2 = manager.items[1]

        XCTAssertEqual(item1, item1)
        XCTAssertNotEqual(item1, item2)
        XCTAssertEqual(item1.kind, .text)
        XCTAssertEqual(item1.text, "Second Item")
        XCTAssertNil(item1.imageData)
        XCTAssertNil(item1.imageType)
        XCTAssertNil(item1.previewImage)
        XCTAssertLessThanOrEqual(item2.createdAt, item1.createdAt)
    }
}
