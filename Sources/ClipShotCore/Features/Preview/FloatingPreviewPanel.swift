import Foundation
import AppKit
import SwiftUI

/// Non-activating floating overlay panel for displaying temporary screenshot preview thumbnails.
public final class FloatingPreviewPanel: NSPanel {
    public static let shared = FloatingPreviewPanel()
    private static let previewSize = NSSize(width: 280, height: 190)

    private var dismissTimer: Timer?
    private var isHovered: Bool = false
    private var currentImage: NSImage?
    private var currentURL: URL?
    private var currentItem: ScreenshotItem?

    public init() {
        super.init(
            contentRect: NSRect(origin: .zero, size: FloatingPreviewPanel.previewSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovableByWindowBackground = false
        self.hidesOnDeactivate = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    /// Displays the preview for a new screenshot.
    public func show(image: NSImage, fileURL: URL, item: ScreenshotItem) {
        self.currentImage = image
        self.currentURL = fileURL
        self.currentItem = item

        let contentView = FloatingPreviewView(
            image: image,
            fileURL: fileURL,
            item: item,
            onHoverChanged: { [weak self] hovering in
                self?.handleHover(hovering)
            },
            onClose: { [weak self] in
                self?.dismiss()
            }
        )

        self.contentViewController = NSHostingController(rootView: contentView)
        setContentSize(Self.previewSize)
        positionOnScreen()
        self.alphaValue = 0.0
        self.orderFrontRegardless()

        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            alphaValue = 1
        } else {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                self.animator().alphaValue = 1
            }
        }

        resetDismissTimer()
    }

    public func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil

        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            alphaValue = 0
            orderOut(nil)
        } else {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.2
                self.animator().alphaValue = 0
            }, completionHandler: {
                self.orderOut(nil)
            })
        }
    }

    private func handleHover(_ hovering: Bool) {
        let pausesOnHover = AppSettings.shared.pausePreviewOnHover
        guard pausesOnHover else {
            isHovered = false
            return
        }
        isHovered = hovering
        if isHovered {
            dismissTimer?.invalidate()
            dismissTimer = nil
        } else {
            resetDismissTimer()
        }
    }

    private func resetDismissTimer() {
        dismissTimer?.invalidate()
        let duration = AppSettings.shared.previewDuration
        dismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            guard let self = self, !self.isHovered else { return }
            self.dismiss()
        }
    }

    private func positionOnScreen() {
        let mouseLocation = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) ?? NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame
        let panelSize = self.frame.size
        let margin: CGFloat = 20.0

        var origin = CGPoint.zero
        let corner = AppSettings.shared.previewCorner

        switch corner {
        case .bottomRight:
            origin = CGPoint(
                x: visibleFrame.maxX - panelSize.width - margin,
                y: visibleFrame.minY + margin
            )
        case .bottomLeft:
            origin = CGPoint(
                x: visibleFrame.minX + margin,
                y: visibleFrame.minY + margin
            )
        case .topRight:
            origin = CGPoint(
                x: visibleFrame.maxX - panelSize.width - margin,
                y: visibleFrame.maxY - panelSize.height - margin
            )
        case .topLeft:
            origin = CGPoint(
                x: visibleFrame.minX + margin,
                y: visibleFrame.maxY - panelSize.height - margin
            )
        }

        self.setFrameOrigin(origin)
    }
}

public struct FloatingPreviewView: View {
    let image: NSImage
    let fileURL: URL
    let item: ScreenshotItem
    let onHoverChanged: (Bool) -> Void
    let onClose: () -> Void

    @State private var isHovering = false
    @State private var isOcrRunning = false
    @State private var copiedConfirmation = true

    public var body: some View {
        VStack(spacing: 0) {
            // Header / Thumbnail (Draggable into any application or Finder)
            ZStack(alignment: .topTrailing) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 260, maxHeight: 130)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(6)
                    .padding(8)
                    .onDrag {
                        NSItemProvider(object: fileURL as NSURL)
                    }

                // Close button (X)
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(12)

                // Status badge
                if copiedConfirmation {
                    VStack {
                        Spacer()
                        HStack {
                            Label("Copied", systemImage: "checkmark")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.75))
                                .cornerRadius(4)
                            Spacer()
                        }
                        .padding(12)
                    }
                }
            }

            Divider()

            // Action Toolbar
            HStack(spacing: 8) {
                ActionButton(icon: "doc.on.doc", tooltip: "Copy Image") {
                    ClipboardManager.shared.copy(image: image, fileURL: fileURL)
                    SoundManager.shared.playCopySound()
                }

                ActionButton(icon: "text.viewfinder", tooltip: "Extract Text (OCR)") {
                    runOCR()
                }

                ActionButton(icon: "pencil.tip.crop.circle", tooltip: "Markup & Edit") {
                    onClose()
                    MarkupWindowController.open(image: image, sourceURL: fileURL)
                }

                ActionButton(icon: "pin.fill", tooltip: "Pin on Screen") {
                    onClose()
                    PinnedImageWindowController.pin(image: image)
                }

                ActionButton(icon: "square.and.arrow.up", tooltip: "Share...") {
                    shareScreenshot()
                }

                ActionButton(icon: "folder", tooltip: "Reveal in Finder") {
                    NSWorkspace.shared.selectFile(fileURL.path, inFileViewerRootedAtPath: fileURL.deletingLastPathComponent().path)
                }

                ActionButton(icon: "trash", tooltip: "Move to Trash") {
                    try? FileManager.default.trashItem(at: fileURL, resultingItemURL: nil)
                    HistoryManager.shared.trashOriginalFile(for: item)
                    onClose()
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.95))
        }
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .onHover { hovering in
            self.isHovering = hovering
            onHoverChanged(hovering)
        }
    }

    private func runOCR() {
        guard !isOcrRunning else { return }
        isOcrRunning = true

        Task {
            if let text = try? await OCRService.shared.recognizeText(from: image) {
                await MainActor.run {
                    onClose()
                    OCRResultWindowController.show(text: text)
                }
            }
            isOcrRunning = false
        }
    }

    private func shareScreenshot() {
        let picker = NSSharingServicePicker(items: [fileURL])
        if let window = NSApp.keyWindow {
            picker.show(relativeTo: .zero, of: window.contentView ?? NSView(), preferredEdge: .minY)
        }
    }
}

private struct ActionButton: View {
    let icon: String
    let tooltip: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(isHovered ? .accentColor : .primary)
                .frame(width: 24, height: 24)
                .background(isHovered ? Color.accentColor.opacity(0.12) : Color.clear)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { isHovered = $0 }
    }
}
