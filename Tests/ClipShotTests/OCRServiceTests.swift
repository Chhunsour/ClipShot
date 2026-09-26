import XCTest
import AppKit
@testable import ClipShotCore

final class OCRServiceTests: XCTestCase {

    func testDetectSmartDataExtractsURLs() {
        let text = "Check out the repo at https://github.com/Chhunsour/ClipShot and docs at https://apple.com"
        let result = OCRService.shared.detectSmartData(in: text)

        XCTAssertEqual(result.urls.count, 2)
        XCTAssertEqual(result.urls.first?.host, "github.com")
    }

    func testDetectSmartDataExtractsEmails() {
        let text = "Reach us at contact@clipshot.app or support@example.com for inquiries"
        let result = OCRService.shared.detectSmartData(in: text)

        XCTAssertTrue(result.emails.contains("contact@clipshot.app"))
        XCTAssertTrue(result.emails.contains("support@example.com"))
    }

    func testDetectSmartDataExtractsPhoneNumbers() {
        let text = "Call our hotline at +1 (555) 123-4567 during business hours"
        let result = OCRService.shared.detectSmartData(in: text)

        XCTAssertFalse(result.phoneNumbers.isEmpty)
    }

    func testRecognizeTextBlankImageReturnsEmpty() async throws {
        let size = NSSize(width: 50, height: 50)
        let blankImage = NSImage(size: size)
        blankImage.lockFocus()
        NSColor.white.drawSwatch(in: NSRect(origin: .zero, size: size))
        blankImage.unlockFocus()

        let text = try await OCRService.shared.recognizeText(from: blankImage)
        XCTAssertEqual(text.trimmingCharacters(in: .whitespacesAndNewlines), "")
    }
}
