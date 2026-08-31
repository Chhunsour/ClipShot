import Foundation
import AppKit
import SwiftUI

/// Controller managing multi-display full-screen capture overlay panels.
@MainActor
public final class CaptureOverlayController {
    public static let shared = CaptureOverlayController()

    private var overlayPanels: [NSPanel] = []
    private var activeMode: CaptureMode = .area

    public init() {}

    /// Displays the capture overlay across all screens.
    public func showOverlay(initialMode: CaptureMode = AppSettings.shared.defaultCaptureMode) {
        dismissOverlay()

        self.activeMode = initialMode

        for screen in NSScreen.screens {
            let panel = NSPanel(
                contentRect: screen.frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )

            panel.level = .screenSaver
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.ignoresMouseEvents = false
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            let contentView = CaptureOverlayView(
                selectedMode: Binding(
                    get: { self.activeMode },
                    set: { self.activeMode = $0 }
                ),
                screenBounds: screen.frame,
                onCaptureRect: { [weak self] rect in
                    self?.handleRectCapture(rect)
                },
                onCaptureWindow: { [weak self] windowInfo in
                    self?.handleWindowCapture(windowInfo)
                },
                onCaptureScreen: { [weak self] in
                    self?.handleScreenCapture(screen)
                },
                onColorSampled: { [weak self] point in
                    self?.handleColorSampled(point)
                },
                onCancel: { [weak self] in
                    self?.dismissOverlay()
                },
                onOpenSettings: { [weak self] in
                    self?.dismissOverlay()
                    SettingsWindowController.shared.showSettings()
                }
            )

            panel.contentViewController = NSHostingController(rootView: contentView)
            panel.setFrame(screen.frame, display: true)
            panel.orderFrontRegardless()

            overlayPanels.append(panel)
        }

        AppLogger.shared.info("Displayed full-screen capture overlay across \(overlayPanels.count) screen(s)")
    }

    public func dismissOverlay() {
        for panel in overlayPanels {
            panel.orderOut(nil)
        }
        overlayPanels.removeAll()
    }

    // MARK: - Post-Capture Handlers

    private func handleRectCapture(_ rect: CGRect) {
        dismissOverlay()

        if activeMode == .ocr {
            if let image = ScreenCaptureEngine.shared.captureRect(rect) {
                Task {
                    if let text = try? await OCRService.shared.recognizeText(from: image) {
                        await MainActor.run {
                            OCRResultWindowController.show(text: text)
                            ClipNotchViewModel.shared.showOCRResult(text: text)
                        }
                    }
                }
            }
            return
        }

        if activeMode == .record {
            ScreenRecordingEngine.shared.startRecording(rect: rect)
            return
        }

        if activeMode == .scrolling {
            ScrollingCaptureService.shared.startCapture(in: rect)
            return
        }

        guard let image = ScreenCaptureEngine.shared.captureRect(rect) else { return }
        processCapturedImage(image)
    }

    private func handleWindowCapture(_ windowInfo: WindowInfo) {
        dismissOverlay()
        let includeShadow = AppSettings.shared.includeWindowShadow
        guard let image = WindowCaptureService.shared.captureWindow(windowInfo, includeShadow: includeShadow) else { return }
        processCapturedImage(image)
    }

    private func handleScreenCapture(_ screen: NSScreen) {
        dismissOverlay()
        guard let image = ScreenCaptureEngine.shared.captureScreen(screen) else { return }
        processCapturedImage(image)
    }

    private func handleColorSampled(_ point: CGPoint) {
        dismissOverlay()
        if let sampled = ColorPickerService.shared.sampleAndFormat(at: point) {
            _ = ColorPickerService.shared.copyColor(at: point)
            ClipNotchViewModel.shared.showColorResult(color: sampled.color, hex: sampled.formattedString)
        }
    }

    private func processCapturedImage(_ image: NSImage) {
        let destinationFolder = PathUtils.shared.activeScreenshotFolder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        let timestamp = formatter.string(from: Date())
        let filename = "ClipShot \(timestamp).png"
        let fileURL = destinationFolder.appendingPathComponent(filename)

        // Save to disk if not in clipboard-only mode
        if !AppSettings.shared.clipboardOnlyMode {
            try? ImageUtils.savePNG(image: image, to: fileURL)
        }

        // Copy to clipboard immediately
        if AppSettings.shared.autoCopyEnabled {
            ClipboardManager.shared.copy(
                image: image,
                fileURL: AppSettings.shared.clipboardOnlyMode ? nil : fileURL,
                mode: AppSettings.shared.clipboardMode
            )
            SoundManager.shared.playCopySound()
        }

        let dims = (Int(image.size.width), Int(image.size.height), Int64(0))

        // Record in history
        HistoryManager.shared.recordScreenshot(
            url: fileURL,
            image: image,
            metadata: dims,
            wasFileTrashed: false
        )

        // Open Editor automatically if configured
        if AppSettings.shared.openEditorAutomatically {
            MarkupWindowController.open(image: image, sourceURL: fileURL)
            return
        }

        let item = ScreenshotItem(
            fileURL: fileURL,
            fileName: filename,
            createdAt: Date(),
            fileSize: 0,
            pixelWidth: dims.0,
            pixelHeight: dims.1
        )

        // Show in ClipNotch
        ClipNotchViewModel.shared.showScreenshot(item: item, image: image)

        // Show floating preview
        if AppSettings.shared.showFloatingPreview {
            FloatingPreviewPanel.shared.show(image: image, fileURL: fileURL, item: item)
        }
    }
}
