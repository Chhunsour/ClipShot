import Foundation
import AppKit

/// Central actor coordinating screenshot ingestion, deduplication, file stability verification,
/// sequence-ordered clipboard updates, history recording, and post-copy file management.
///
/// ## Actor Isolation & Concurrency
/// As a Swift actor, `ScreenshotProcessor` serializes access to mutable state (`sequenceCounter`,
/// `latestClipboardSequence`, `processedEvents`), guaranteeing zero data races when concurrent
/// filesystem events fire simultaneously across multi-monitor or rapid-capture scenarios.
///
/// ## 8-Step Processing Pipeline
/// 1. **Deduplication Check**: Queries sliding cache to eliminate redundant events within milliseconds.
/// 2. **File Write Stability**: Probes file size across 5ms micro-waits until macOS flush completes.
/// 3. **Validation**: Passes candidate through `ScreenshotDetector` rules.
/// 4. **Decoding**: Loads bitmap rep and metadata on background cooperative thread pool.
/// 5. **Sequence-Guarded Clipboard**: Enforces strictly monotonic sequence order so older captures
///    never overwrite newer captures.
/// 6. **Post-Copy Actions**: Trashes original file or schedules delayed auto-deletion if requested.
/// 7. **History Journaling**: Persists snapshot to local SQLite/disk history.
/// 8. **UI Presentation**: Signals ClipNotch or floating preview window on `@MainActor`.
public actor ScreenshotProcessor {
    /// Shared singleton actor instance.
    public static let shared = ScreenshotProcessor()

    /// Monotonically increasing sequence ID assigned to each validated screenshot.
    private var sequenceCounter: UInt64 = 0

    /// Highest sequence ID that has been successfully written to the system pasteboard.
    private var latestClipboardSequence: UInt64 = 0

    /// Inode / Path + modification timestamp cache to avoid duplicate processing of burst events.
    private var processedEvents: [String: TimeInterval] = [:]

    /// Optional callback to trigger floating preview presentation on MainActor.
    private var previewCallback: (@MainActor (URL, NSImage, ScreenshotItem) -> Void)?

    /// Default initializer.
    public init() {}

    /// Registers a closure to be executed on the MainActor when a screenshot is ready for display.
    /// - Parameter callback: Closure receiving file URL, decoded NSImage, and ScreenshotItem model.
    public func setPreviewCallback(_ callback: @escaping @MainActor (URL, NSImage, ScreenshotItem) -> Void) {
        self.previewCallback = callback
    }

    /// Main entry point: processes a detected file candidate URL from the filesystem monitor.
    ///
    /// Executes the full 8-step pipeline with deduplication, stability verification, and UI dispatch.
    ///
    /// - Parameter url: Filesystem URL of the newly created or modified file.
    public func processCandidate(url: URL) async {
        let settings = AppSettings.shared
        guard settings.monitoringActive else {
            AppLogger.shared.debug("Monitoring is paused, ignoring candidate: \(url.lastPathComponent)")
            return
        }

        // Ignore temporary hidden dot files
        guard !url.lastPathComponent.hasPrefix(".") else { return }

        // 1. Deduplication check
        let now = Date().timeIntervalSince1970
        cleanExpiredEvents(now: now)

        let eventKey = makeEventKey(for: url)
        if let lastProcessed = processedEvents[eventKey], (now - lastProcessed) < AppConfig.recentEventCacheDuration {
            AppLogger.shared.debug("Ignoring duplicate event for: \(url.lastPathComponent)")
            return
        }

        // 2. File stability check (wait for macOS screenshot write completion)
        guard await waitForFileStability(url: url) else {
            AppLogger.shared.warning("File stability check timed out for: \(url.lastPathComponent)")
            return
        }

        // 3. Screenshot validation
        guard ScreenshotDetector.shared.isScreenshot(url: url, settings: settings) else {
            AppLogger.shared.debug("Candidate rejected by detector: \(url.lastPathComponent)")
            return
        }

        // Mark as processed
        processedEvents[eventKey] = now
        sequenceCounter += 1
        let currentSequence = sequenceCounter

        AppLogger.shared.info("Processing screenshot [seq #\(currentSequence)]: \(url.lastPathComponent)")

        // 4. Load image data & metadata off the main thread
        guard let image = ImageUtils.loadImage(at: url) else {
            AppLogger.shared.error("Failed to load image at: \(url.lastPathComponent)")
            return
        }

        let metadata = ImageUtils.getImageMetadata(at: url)

        // 5. Sequence-protected Clipboard copy
        var clipboardCopied = false
        if settings.autoCopyEnabled {
            if currentSequence >= latestClipboardSequence {
                latestClipboardSequence = currentSequence
                clipboardCopied = await MainActor.run {
                    ClipboardManager.shared.copy(
                        image: image,
                        fileURL: url,
                        mode: settings.clipboardMode
                    )
                }

                if clipboardCopied {
                    SoundManager.shared.playCopySound()
                }
            } else {
                AppLogger.shared.info("Skipping clipboard overwrite for older sequence #\(currentSequence) (latest is #\(latestClipboardSequence))")
            }
        }

        // 6. Post-copy file actions (Trash / Delayed delete)
        var fileWasTrashed = false
        let shouldTrash = settings.clipboardOnlyMode || settings.afterCopyAction == .trash

        if shouldTrash && clipboardCopied {
            do {
                try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                fileWasTrashed = true
                AppLogger.shared.info("Moved screenshot to Trash: \(url.lastPathComponent)")
            } catch {
                AppLogger.shared.error("Failed to trash screenshot: \(error.localizedDescription)")
            }
        } else if settings.afterCopyAction == .deleteAfterDelay && clipboardCopied {
            let delaySeconds = settings.deleteAfterDelaySeconds
            Task.detached {
                try? await Task.sleep(nanoseconds: UInt64(delaySeconds) * 1_000_000_000)
                try? FileManager.default.trashItem(at: url, resultingItemURL: nil)
                AppLogger.shared.info("Delayed trash executed for: \(url.lastPathComponent)")
            }
        }

        // 7. Record to History
        HistoryManager.shared.recordScreenshot(
            url: url,
            image: image,
            metadata: metadata,
            wasFileTrashed: fileWasTrashed
        )

        // 8. Show one confirmation surface: ClipNotch or the floating preview.
        if settings.showFloatingPreview && !settings.clipNotchEnabled {
            let dims = metadata ?? (Int(image.size.width), Int(image.size.height), 0)
            let item = ScreenshotItem(
                fileURL: url,
                fileName: url.lastPathComponent,
                createdAt: Date(),
                fileSize: dims.fileSize,
                pixelWidth: dims.width,
                pixelHeight: dims.height,
                isDeletedFromDisk: fileWasTrashed
            )

            if let callback = previewCallback {
                await MainActor.run {
                    callback(url, image, item)
                    ClipNotchViewModel.shared.showScreenshot(item: item, image: image)
                }
            } else {
                await MainActor.run {
                    ClipNotchViewModel.shared.showScreenshot(item: item, image: image)
                }
            }
        } else if settings.clipNotchEnabled {
            let dims = metadata ?? (Int(image.size.width), Int(image.size.height), 0)
            let item = ScreenshotItem(
                fileURL: url,
                fileName: url.lastPathComponent,
                createdAt: Date(),
                fileSize: dims.fileSize,
                pixelWidth: dims.width,
                pixelHeight: dims.height,
                isDeletedFromDisk: fileWasTrashed
            )
            await MainActor.run {
                ClipNotchViewModel.shared.showScreenshot(item: item, image: image)
            }
        }
    }

    // MARK: - Stability & Deduplication Helpers

    /// Verifies file exists, is non-zero, and is completely written. Returns immediately if valid.
    private func waitForFileStability(url: URL) async -> Bool {
        let fm = FileManager.default

        // Fast path: if file is already valid, return immediately with 0 delay
        if fm.fileExists(atPath: url.path) && ImageUtils.isValidImage(at: url) {
            return true
        }

        var lastSize: Int64 = -1
        for _ in 0..<AppConfig.maxFileStabilityRetries {
            guard fm.fileExists(atPath: url.path) else { return false }

            if let attrs = try? fm.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? Int64,
               size > 0 {

                if (size == lastSize || size > 0) && ImageUtils.isValidImage(at: url) {
                    return true
                }
                lastSize = size
            }

            try? await Task.sleep(nanoseconds: 5_000_000) // 5ms micro-wait
        }

        return ImageUtils.isValidImage(at: url)
    }

    /// Generates a collision-resistant deduplication key combining the filesystem inode and modification timestamp.
    private func makeEventKey(for url: URL) -> String {
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let fileNumber = attrs[.systemFileNumber] as? UInt,
           let modDate = attrs[.modificationDate] as? Date {
            return "\(fileNumber)_\(modDate.timeIntervalSince1970)"
        }
        return url.path
    }

    /// Evicts stale deduplication cache entries older than the sliding event cache window.
    private func cleanExpiredEvents(now: TimeInterval) {
        let cutoff = now - 1.5 // 1.5 second cache window for rapid bursts
        processedEvents = processedEvents.filter { $0.value >= cutoff }
    }
}
