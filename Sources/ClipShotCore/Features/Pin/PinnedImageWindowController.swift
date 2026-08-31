import Foundation
import AppKit
import SwiftUI

/// Borderless floating window controller for pinning reference screenshots on top of all windows.
public final class PinnedImageWindowController: NSWindowController {
    public static var pinnedWindows: [PinnedImageWindowController] = []

    public static func pin(image: NSImage, title: String = "Pinned Screenshot") {
        let controller = PinnedImageWindowController(image: image, title: title)
        pinnedWindows.append(controller)
        controller.showWindow(nil)
    }

    private let image: NSImage

    init(image: NSImage, title: String) {
        self.image = image

        let initialWidth = min(max(image.size.width, 240), 600)
        let aspectRatio = image.size.height > 0 ? image.size.width / image.size.height : 1.0
        let initialHeight = initialWidth / aspectRatio

        let panel = NSPanel(
            contentRect: NSRect(x: 200, y: 200, width: initialWidth, height: initialHeight),
            styleMask: [.borderless, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.isMovableByWindowBackground = true
        panel.hasShadow = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.aspectRatio = NSSize(width: image.size.width, height: image.size.height)

        super.init(window: panel)

        let contentView = PinnedImageView(
            image: image,
            onClose: { [weak self] in self?.closeWindow() },
            onChangeOpacity: { [weak panel] opacity in panel?.alphaValue = opacity }
        )
        panel.contentViewController = NSHostingController(rootView: contentView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func closeWindow() {
        window?.close()
        PinnedImageWindowController.pinnedWindows.removeAll { $0 === self }
    }
}

public struct PinnedImageView: View {
    let image: NSImage
    let onClose: () -> Void
    let onChangeOpacity: (CGFloat) -> Void

    @State private var isHovered: Bool = false
    @State private var currentOpacity: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)

            // Hover controls
            if isHovered {
                HStack(spacing: 6) {
                    // Close button
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Close pinned image")
                }
                .padding(8)
                .transition(.opacity)
            }
        }
        .onHover { hovering in
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Menu("Opacity") {
                Button("100%") { setOpacity(1.0) }
                Button("75%") { setOpacity(0.75) }
                Button("50%") { setOpacity(0.50) }
                Button("25%") { setOpacity(0.25) }
            }

            Divider()

            Button("Copy Image") {
                ClipboardManager.shared.copy(image: image)
            }

            Button("Save As...") {
                saveImageAs()
            }

            Divider()

            Button("Close") {
                onClose()
            }
        }
    }

    private func setOpacity(_ opacity: CGFloat) {
        currentOpacity = opacity
        onChangeOpacity(opacity)
    }

    private func saveImageAs() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = "Pinned Screenshot.png"

        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                try? ImageUtils.savePNG(image: image, to: url)
            }
        }
    }
}
