import Foundation

/// Represents a single recorded screenshot in ClipShot history.
public struct ScreenshotItem: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var fileURL: URL
    public var fileName: String
    public let createdAt: Date
    public var fileSize: Int64
    public var pixelWidth: Int
    public var pixelHeight: Int
    public var isDeletedFromDisk: Bool
    public var thumbnailCachedPath: String?
    public var preservedCopyPath: String?

    public init(
        id: UUID = UUID(),
        fileURL: URL,
        fileName: String? = nil,
        createdAt: Date = Date(),
        fileSize: Int64 = 0,
        pixelWidth: Int = 0,
        pixelHeight: Int = 0,
        isDeletedFromDisk: Bool = false,
        thumbnailCachedPath: String? = nil,
        preservedCopyPath: String? = nil
    ) {
        self.id = id
        self.fileURL = fileURL
        self.fileName = fileName ?? fileURL.lastPathComponent
        self.createdAt = createdAt
        self.fileSize = fileSize
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.isDeletedFromDisk = isDeletedFromDisk
        self.thumbnailCachedPath = thumbnailCachedPath
        self.preservedCopyPath = preservedCopyPath
    }

    /// Formatted dimensions string, e.g. "1920 × 1080".
    public var dimensionsString: String {
        guard pixelWidth > 0 && pixelHeight > 0 else { return "Unknown size" }
        return "\(pixelWidth) × \(pixelHeight)"
    }

    /// Formatted file size string, e.g. "2.1 MB" or "540 KB".
    public var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    /// Relative time string or short time, e.g. "11:04 AM" or "Yesterday".
    public var formattedTime: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(createdAt) {
            formatter.timeStyle = .short
            formatter.dateStyle = .none
        } else {
            formatter.timeStyle = .short
            formatter.dateStyle = .short
        }
        return formatter.string(from: createdAt)
    }

    /// Section grouping title, e.g. "Today", "Yesterday", or "MMMM d, yyyy".
    public var sectionTitle: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(createdAt) {
            return "Today"
        } else if calendar.isDateInYesterday(createdAt) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: createdAt)
        }
    }

    /// Returns the effective image URL (either live file or preserved local copy).
    public var effectiveImageURL: URL? {
        if !isDeletedFromDisk && FileManager.default.fileExists(atPath: fileURL.path) {
            return fileURL
        }
        if let preservedPath = preservedCopyPath, FileManager.default.fileExists(atPath: preservedPath) {
            return URL(fileURLWithPath: preservedPath)
        }
        return nil
    }
}
