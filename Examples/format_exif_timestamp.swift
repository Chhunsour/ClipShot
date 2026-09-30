#!/usr/bin/env swift
import Foundation

print("--- ClipShot: EXIF / TIFF DateTimeOriginal & Metadata Timestamp Parser ---")

struct EXIFDateParser {
    // Standard TIFF/EXIF format: "yyyy:MM:dd HH:mm:ss"
    private static let exifFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy:MM:dd HH:mm:ss"
        df.timeZone = TimeZone.current
        return df
    }()

    // ISO 8601 Formatter for clean archival and JSON output
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    // Localized User-Facing Formatter
    private static let localizedFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .medium
        return df
    }()

    static func parseEXIFString(_ dateString: String) -> Date? {
        return exifFormatter.date(from: dateString)
    }

    static func formatToEXIF(_ date: Date) -> String {
        return exifFormatter.string(from: date)
    }

    static func formatToISO8601(_ date: Date) -> String {
        return iso8601Formatter.string(from: date)
    }

    static func formatToLocalized(_ date: Date) -> String {
        return localizedFormatter.string(from: date)
    }
}

// Simulated ImageIO CGImageSourceCopyPropertiesAtIndex dictionaries
let sampleMetadataDicts: [[String: Any]] = [
    [
        "{TIFF}": [
            "DateTime": "2026:09:30 08:15:22",
            "Make": "Apple",
            "Model": "MacBookPro18,1"
        ],
        "{Exif}": [
            "DateTimeOriginal": "2026:09:30 08:15:22",
            "SubsecTimeOriginal": "421"
        ],
        "PixelWidth": 3024,
        "PixelHeight": 1964
    ],
    [
        "{TIFF}": [
            "DateTime": "2025:12:31 23:59:59"
        ],
        "{Exif}": [
            "DateTimeOriginal": "2025:12:31 23:59:59"
        ],
        "PixelWidth": 1920,
        "PixelHeight": 1080
    ],
    [
        "{TIFF}": [
            "DateTime": "invalid_date_format"
        ],
        "PixelWidth": 800,
        "PixelHeight": 600
    ]
]

print(String(format: "%-6@ %-22@ %-30@ %-24@", "Item", "Raw EXIF String", "ISO-8601 Representation", "Localized Display"))
print(String(repeating: "-", count: 88))

for (idx, dict) in sampleMetadataDicts.enumerated() {
    var rawDateStr: String? = nil
    if let exif = dict["{Exif}"] as? [String: Any], let date = exif["DateTimeOriginal"] as? String {
        rawDateStr = date
    } else if let tiff = dict["{TIFF}"] as? [String: Any], let date = tiff["DateTime"] as? String {
        rawDateStr = date
    }

    if let raw = rawDateStr, let parsed = EXIFDateParser.parseEXIFString(raw) {
        let iso = EXIFDateParser.formatToISO8601(parsed)
        let loc = EXIFDateParser.formatToLocalized(parsed)
        print(String(format: "#%-5d %-22@ %-30@ %-24@", idx + 1, raw, iso, loc))
    } else {
        print(String(format: "#%-5d %-22@ %-30@ %-24@", idx + 1, rawDateStr ?? "nil", "[Parsing Failed / Fallback]", "[Current Date]"))
    }
}

print("\n--- Current Capture Timestamp Encoding ---")
let now = Date()
print("Now (Date object):        \(now)")
print("Encoded for {Exif} tag:   \"\(EXIFDateParser.formatToEXIF(now))\"")
print("Encoded for ISO metadata: \"\(EXIFDateParser.formatToISO8601(now))\"")

print("\nArchitectural Rationale: Normalizing colon-delimited EXIF timestamps (yyyy:MM:dd) to standard ISO-8601 dates prevents timezone offsets and invalid date bugs when indexing screenshot metadata.")
