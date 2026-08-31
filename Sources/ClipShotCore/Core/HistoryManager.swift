import Foundation
import AppKit
import Combine

/// Manages screenshot history indexing, thumbnail caching, and retention pruning.
public final class HistoryManager: ObservableObject, @unchecked Sendable {
    public static let shared = HistoryManager()

    @Published public private(set) var items: [ScreenshotItem] = []

    private let queue = DispatchQueue(label: "com.clipshot.history", qos: .utility)
    private let fileManager = FileManager.default

    private let appSupportURL: URL
    private let historyFileURL: URL
    private let thumbnailCacheURL: URL
    private let preservedCopiesURL: URL

    public init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.appSupportURL = appSupport.appendingPathComponent("ClipShot")
        self.historyFileURL = appSupportURL.appendingPathComponent("history.json")

        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.thumbnailCacheURL = caches.appendingPathComponent("ClipShot").appendingPathComponent("thumbnails")
        self.preservedCopiesURL = appSupportURL.appendingPathComponent("Preserved")

        createDirectories()
        loadHistory()
        pruneHistory()
    }

    private func createDirectories() {
        try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: thumbnailCacheURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: preservedCopiesURL, withIntermediateDirectories: true)
    }

    // MARK: - Public API

    /// Records a newly detected screenshot and caches its thumbnail.
    public func recordScreenshot(
        url: URL,
        image: NSImage,
        metadata: (width: Int, height: Int, fileSize: Int64)? = nil,
        wasFileTrashed: Bool = false
    ) {
        guard AppSettings.shared.historyEnabled else { return }

        queue.async { [weak self] in
            guard let self = self else { return }

            let id = UUID()
            let thumbPath = self.thumbnailCacheURL.appendingPathComponent("\(id.uuidString).png").path

            // Save downscaled thumbnail
            if let thumb = ImageUtils.generateThumbnail(from: url, maxDimension: 320) ?? image.copy() as? NSImage {
                try? ImageUtils.savePNG(image: thumb, to: URL(fileURLWithPath: thumbPath))
            }

            // If file was trashed and preserve copies is enabled, store a copy
            var preservedPath: String?
            if wasFileTrashed && AppSettings.shared.storeDeletedScreenshotCopies {
                let pPath = self.preservedCopiesURL.appendingPathComponent("\(id.uuidString).png").path
                try? ImageUtils.savePNG(image: image, to: URL(fileURLWithPath: pPath))
                preservedPath = pPath
            }

            let dims = metadata ?? (Int(image.size.width), Int(image.size.height), 0)

            let item = ScreenshotItem(
                id: id,
                fileURL: url,
                fileName: url.lastPathComponent,
                createdAt: Date(),
                fileSize: dims.fileSize,
                pixelWidth: dims.width,
                pixelHeight: dims.height,
                isDeletedFromDisk: wasFileTrashed,
                thumbnailCachedPath: thumbPath,
                preservedCopyPath: preservedPath
            )

            DispatchQueue.main.async {
                self.items.insert(item, at: 0)
                self.saveHistoryAsync()
                self.pruneHistory()
            }
        }
    }

    /// Returns the most recent screenshot item if available.
    public var lastScreenshot: ScreenshotItem? {
        items.first
    }

    /// Deletes a specific screenshot record and its thumbnail.
    public func deleteItem(_ item: ScreenshotItem) {
        DispatchQueue.main.async {
            self.items.removeAll { $0.id == item.id }
            self.saveHistoryAsync()
        }

        queue.async { [weak self] in
            guard let self = self else { return }
            if let thumbPath = item.thumbnailCachedPath {
                try? self.fileManager.removeItem(atPath: thumbPath)
            }
            if let preserved = item.preservedCopyPath {
                try? self.fileManager.removeItem(atPath: preserved)
            }
        }
    }

    /// Moves the original file to Trash and marks item as deleted.
    public func trashOriginalFile(for item: ScreenshotItem) {
        if FileManager.default.fileExists(atPath: item.fileURL.path) {
            try? FileManager.default.trashItem(at: item.fileURL, resultingItemURL: nil)
        }

        DispatchQueue.main.async {
            if let index = self.items.firstIndex(where: { $0.id == item.id }) {
                self.items[index].isDeletedFromDisk = true
                self.saveHistoryAsync()
            }
        }
    }

    /// Clears all screenshot history and removes all cached thumbnails.
    public func clearHistory() {
        DispatchQueue.main.async {
            self.items.removeAll()
            self.saveHistoryAsync()
        }

        queue.async { [weak self] in
            guard let self = self else { return }
            try? self.fileManager.removeItem(at: self.thumbnailCacheURL)
            try? self.fileManager.removeItem(at: self.preservedCopiesURL)
            self.createDirectories()
        }
    }

    /// Retrieves the thumbnail image for a given item.
    public func loadThumbnail(for item: ScreenshotItem) -> NSImage? {
        if let path = item.thumbnailCachedPath, fileManager.fileExists(atPath: path) {
            return NSImage(contentsOfFile: path)
        }
        if fileManager.fileExists(atPath: item.fileURL.path) {
            return ImageUtils.generateThumbnail(from: item.fileURL, maxDimension: 320)
        }
        return nil
    }

    // MARK: - Persistence & Pruning

    private func loadHistory() {
        guard fileManager.fileExists(atPath: historyFileURL.path),
              let data = try? Data(contentsOf: historyFileURL),
              let loaded = try? JSONDecoder().decode([ScreenshotItem].self, from: data) else {
            return
        }
        DispatchQueue.main.async {
            self.items = loaded
            self.validateDiskExistence()
        }
    }

    private func saveHistoryAsync() {
        let itemsToSave = self.items
        queue.async { [weak self] in
            guard let self = self else { return }
            if let data = try? JSONEncoder().encode(itemsToSave) {
                try? data.write(to: self.historyFileURL, options: .atomic)
            }
        }
    }

    private func validateDiskExistence() {
        for i in 0..<items.count {
            let exists = fileManager.fileExists(atPath: items[i].fileURL.path)
            items[i].isDeletedFromDisk = !exists
        }
    }

    /// Prunes items exceeding max count or older than retention period.
    public func pruneHistory() {
        let settings = AppSettings.shared

        // 1. Max items limit
        if settings.historyLimit != .unlimited {
            let limit = settings.historyLimit.rawValue
            if items.count > limit {
                let excess = Array(items.suffix(from: limit))
                items = Array(items.prefix(limit))
                excess.forEach { deleteItem($0) }
            }
        }

        // 2. Retention duration
        if settings.historyRetention != .unlimited {
            let days = Double(settings.historyRetention.rawValue)
            let cutoffDate = Date().addingTimeInterval(-days * 86400.0)

            let expired = items.filter { $0.createdAt < cutoffDate }
            if !expired.isEmpty {
                items.removeAll { $0.createdAt < cutoffDate }
                expired.forEach { deleteItem($0) }
            }
        }

        saveHistoryAsync()
    }
}
