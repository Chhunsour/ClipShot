import XCTest
import Vision
@testable import ClipShotCore

final class OCRConfidenceFilteringTests: XCTestCase {

    struct MockRecognizedCandidate {
        let string: String
        let confidence: Float
    }

    private func filterCandidates(_ candidates: [MockRecognizedCandidate], minConfidence: Float) -> [MockRecognizedCandidate] {
        return candidates.filter { $0.confidence >= minConfidence }
    }

    func testConfidenceThresholdFiltering() {
        let candidates = [
            MockRecognizedCandidate(string: "HighConfidenceCode", confidence: 0.95),
            MockRecognizedCandidate(string: "MediumConfidenceWord", confidence: 0.65),
            MockRecognizedCandidate(string: "NoiseArtifact--", confidence: 0.25),
            MockRecognizedCandidate(string: "~`^", confidence: 0.05)
        ]

        let filteredStrict = filterCandidates(candidates, minConfidence: 0.70)
        XCTAssertEqual(filteredStrict.count, 1)
        XCTAssertEqual(filteredStrict.first?.string, "HighConfidenceCode")

        let filteredBalanced = filterCandidates(candidates, minConfidence: 0.50)
        XCTAssertEqual(filteredBalanced.count, 2)
        XCTAssertEqual(filteredBalanced.map { $0.string }, ["HighConfidenceCode", "MediumConfidenceWord"])

        let filteredPermissive = filterCandidates(candidates, minConfidence: 0.10)
        XCTAssertEqual(filteredPermissive.count, 3)
    }

    func testConfidenceRankingSort() {
        let candidates = [
            MockRecognizedCandidate(string: "OptionC", confidence: 0.40),
            MockRecognizedCandidate(string: "OptionA", confidence: 0.92),
            MockRecognizedCandidate(string: "OptionB", confidence: 0.78)
        ]

        let sorted = candidates.sorted { $0.confidence > $1.confidence }
        XCTAssertEqual(sorted.first?.string, "OptionA")
        XCTAssertEqual(sorted.last?.string, "OptionC")
    }

    func testConfidenceBoundsClamping() {
        func clampConfidence(_ value: Float) -> Float {
            return min(max(value, 0.0), 1.0)
        }

        XCTAssertEqual(clampConfidence(1.25), 1.0)
        XCTAssertEqual(clampConfidence(-0.35), 0.0)
        XCTAssertEqual(clampConfidence(0.85), 0.85)
    }

    func testDetectSmartDataWithMultipleEntities() {
        let text = """
        Review documentation at https://github.com/Chhunsour/ClipShot
        For security audits, contact support@clipshot.app or call +1 (555) 234-5678.
        """

        let (urls, emails, phones) = OCRService.shared.detectSmartData(in: text)

        XCTAssertEqual(urls.count, 1)
        XCTAssertEqual(urls.first?.host, "github.com")

        XCTAssertEqual(emails.count, 1)
        XCTAssertEqual(emails.first, "support@clipshot.app")

        XCTAssertEqual(phones.count, 1)
        XCTAssertTrue(phones.first?.contains("555") == true)
    }

    func testDetectSmartDataWithPlainTextReturnsEmpty() {
        let plainText = "Standard screenshot with no detectable links or numbers."
        let (urls, emails, phones) = OCRService.shared.detectSmartData(in: plainText)

        XCTAssertTrue(urls.isEmpty)
        XCTAssertTrue(emails.isEmpty)
        XCTAssertTrue(phones.isEmpty)
    }
}
