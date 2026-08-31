import Foundation
import AppKit
import SwiftUI

public struct PaletteCommand: Identifiable {
    public let id = UUID()
    public let title: String
    public let subtitle: String
    public let iconName: String
    public let action: () -> Void
}

public final class CommandPaletteWindowController: NSWindowController {
    public static let shared = CommandPaletteWindowController()

    public init() {
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 280),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.center()

        super.init(window: window)

        let contentView = CommandPaletteView(onDismiss: { [weak self] in
            self?.dismissPalette()
        })
        window.contentViewController = NSHostingController(rootView: contentView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func togglePalette() {
        if window?.isVisible == true {
            dismissPalette()
        } else {
            showPalette()
        }
    }

    public func showPalette() {
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func dismissPalette() {
        window?.orderOut(nil)
    }
}

public struct CommandPaletteView: View {
    let onDismiss: () -> Void

    @State private var query: String = ""
    @State private var selectedIndex: Int = 0

    private var allCommands: [PaletteCommand] {
        [
            PaletteCommand(title: "Capture Area", subtitle: "Select region to screenshot", iconName: "crop") {
                onDismiss()
                CaptureOverlayController.shared.showOverlay(initialMode: .area)
            },
            PaletteCommand(title: "Capture Window", subtitle: "Highlight and capture on-screen window", iconName: "rectangle.inset.filled") {
                onDismiss()
                CaptureOverlayController.shared.showOverlay(initialMode: .window)
            },
            PaletteCommand(title: "Capture Full Screen", subtitle: "Capture entire display", iconName: "macwindow") {
                onDismiss()
                CaptureOverlayController.shared.showOverlay(initialMode: .screen)
            },
            PaletteCommand(title: "Extract Text (OCR)", subtitle: "Recognize and copy text from screen", iconName: "text.viewfinder") {
                onDismiss()
                CaptureOverlayController.shared.showOverlay(initialMode: .ocr)
            },
            PaletteCommand(title: "Record Screen", subtitle: "Record screen video or animated GIF", iconName: "record.circle") {
                onDismiss()
                CaptureOverlayController.shared.showOverlay(initialMode: .record)
            },
            PaletteCommand(title: "Color Picker", subtitle: "Inspect pixel colors in HEX / RGB / HSL", iconName: "eyedropper") {
                onDismiss()
                CaptureOverlayController.shared.showOverlay(initialMode: .colorPicker)
            },
            PaletteCommand(title: "Measure Distance", subtitle: "Pixel ruler and dimension measurement", iconName: "ruler") {
                onDismiss()
                CaptureOverlayController.shared.showOverlay(initialMode: .measure)
            },
            PaletteCommand(title: "Screenshot History", subtitle: "Browse past screenshots and annotations", iconName: "clock") {
                onDismiss()
                HistoryWindowController.shared.showHistory()
            },
            PaletteCommand(title: "ClipShot Settings", subtitle: "Configure shortcuts, preferences, and output", iconName: "gearshape") {
                onDismiss()
                SettingsWindowController.shared.showSettings()
            }
        ]
    }

    private var filteredCommands: [PaletteCommand] {
        if query.isEmpty { return allCommands }
        return allCommands.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.subtitle.localizedCaseInsensitiveContains(query)
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)

                TextField("Type a command (e.g. area, ocr, record)...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))

                if !query.isEmpty {
                    Button(action: { query = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)

            Divider()

            // Command List
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(filteredCommands.enumerated()), id: \.element.id) { index, cmd in
                        Button(action: cmd.action) {
                            HStack(spacing: 10) {
                                Image(systemName: cmd.iconName)
                                    .font(.system(size: 14))
                                    .frame(width: 24)
                                    .foregroundColor(.accentColor)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(cmd.title)
                                        .font(.system(size: 13, weight: .medium))
                                    Text(cmd.subtitle)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedIndex == index ? Color.accentColor.opacity(0.15) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(6)
            }
            .frame(maxHeight: 200)
        }
        .background(
            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.4), radius: 16, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}
