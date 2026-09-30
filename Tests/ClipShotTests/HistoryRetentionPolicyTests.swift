import XCTest
import Foundation
@testable import ClipShotCore

final class HistoryRetentionPolicyTests: XCTestCase {

    func testCodableSerializationRoundtrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for original in HistoryRetention.allCases {
            let data = try encoder.encode(original)
            let decoded = try decoder.decode(HistoryRetention.self, from: data)
            XCTAssertEqual(decoded, original)
        }
    }

    func testIdentifiableIDsMatchRawValues() {
        for policy in HistoryRetention.allCases {
            XCTAssertEqual(policy.id, policy.rawValue)
        }
    }

    func testInvalidRawValuesReturnNil() {
        XCTAssertNil(HistoryRetention(rawValue: -1))
        XCTAssertNil(HistoryRetention(rawValue: 3))
        XCTAssertNil(HistoryRetention(rawValue: 15))
        XCTAssertNil(HistoryRetention(rawValue: 365))
    }

    func testRetentionCutoffDateCalculations() {
        let referenceDate = Date(timeIntervalSince1970: 1700000000) // Fixed point in time

        func cutoffDate(for policy: HistoryRetention, from ref: Date) -> Date? {
            guard policy.rawValue > 0 else { return nil }
            return Calendar.current.date(byAdding: .day, value: -policy.rawValue, to: ref)
        }

        XCTAssertNil(cutoffDate(for: .unlimited, from: referenceDate))

        if let oneDayCutoff = cutoffDate(for: .oneDay, from: referenceDate) {
            let diff = referenceDate.timeIntervalSince(oneDayCutoff)
            XCTAssertEqual(diff, 86400, accuracy: 1.0)
        } else {
            XCTFail("One day cutoff should not be nil")
        }

        if let sevenDaysCutoff = cutoffDate(for: .sevenDays, from: referenceDate) {
            let diff = referenceDate.timeIntervalSince(sevenDaysCutoff)
            XCTAssertEqual(diff, 7 * 86400, accuracy: 1.0)
        } else {
            XCTFail("Seven days cutoff should not be nil")
        }
    }

    func testItemPruningPredicateSimulation() {
        let now = Date(timeIntervalSince1970: 1700000000)
        let item1 = now.addingTimeInterval(-3600) // 1 hour ago
        let item2 = now.addingTimeInterval(-2 * 86400) // 2 days ago
        let item3 = now.addingTimeInterval(-10 * 86400) // 10 days ago

        let timestamps = [item1, item2, item3]

        func retainTimestamps(policy: HistoryRetention) -> [Date] {
            guard policy.rawValue > 0 else { return timestamps }
            let cutoff = now.addingTimeInterval(-Double(policy.rawValue) * 86400)
            return timestamps.filter { $0 >= cutoff }
        }

        // Unlimited retains all
        XCTAssertEqual(retainTimestamps(policy: .unlimited).count, 3)

        // 1 day retains only item1
        XCTAssertEqual(retainTimestamps(policy: .oneDay).count, 1)

        // 7 days retains item1 and item2
        XCTAssertEqual(retainTimestamps(policy: .sevenDays).count, 2)

        // 30 days retains all 3
        XCTAssertEqual(retainTimestamps(policy: .thirtyDays).count, 3)
    }
}
