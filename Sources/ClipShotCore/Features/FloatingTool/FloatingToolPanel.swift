import Foundation
import AppKit
import SwiftUI

/// Floating screen dock widget displayed on the edge of the screen for quick capture access.
public final class FloatingToolPanel: NSPanel {
    public static let shared = FloatingToolPanel()

    public init() {
        super.init(
            contentRect: NSRect(x: 20, y: 300, width: 44, height: 44),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovableByWindowBackground = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let contentView = FloatingToolView()
        self.contentViewController = NSHostingController(rootView: contentView)
    }

    public func updateVisibility() {
        let style = AppSettings.shared.floatingToolStyle
        if style == .hidden {
            self.orderOut(nil)
        } else {
            self.orderFront(nil)
        }
    }
}

public struct FloatingToolView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var isExpanded: Bool = false
    @State private var isHovered: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public var body: some View {
        Group {
            if isExpanded || settings.floatingToolStyle == .expanded {
                expandedDock
            } else {
                collapsedButton
            }
        }
        .onHover { hovering in
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.15)) {
                isHovered = hovering
                if settings.floatingToolAutoCollapse && settings.floatingToolStyle == .button {
                    isExpanded = hovering
                }
            }
        }
    }

    private var collapsedButton: some View {
        Button(action: {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) { isExpanded.toggle() }
        }) {
            ZStack {
                Circle()
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)

                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
        .help("ClipShot Tools")
    }

    private var expandedDock: some View {
        VStack(spacing: 4) {
            dockItem(icon: "crop", label: "Area") {
                CaptureOverlayController.shared.showOverlay(initialMode: .area)
            }
            dockItem(icon: "rectangle.inset.filled", label: "Window") {
                CaptureOverlayController.shared.showOverlay(initialMode: .window)
            }
            dockItem(icon: "macwindow", label: "Screen") {
                CaptureOverlayController.shared.showOverlay(initialMode: .screen)
            }
            dockItem(icon: "text.viewfinder", label: "OCR") {
                CaptureOverlayController.shared.showOverlay(initialMode: .ocr)
            }
            dockItem(icon: "record.circle", label: "Record") {
                CaptureOverlayController.shared.showOverlay(initialMode: .record)
            }
            dockItem(icon: "eyedropper", label: "Color") {
                CaptureOverlayController.shared.showOverlay(initialMode: .colorPicker)
            }
            dockItem(icon: "ruler", label: "Measure") {
                CaptureOverlayController.shared.showOverlay(initialMode: .measure)
            }
            dockItem(icon: "clock", label: "History") {
                HistoryWindowController.shared.showHistory()
            }
        }
        .padding(6)
        .background(
            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private func dockItem(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 18)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                Spacer()
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color.primary.opacity(0.001))
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}
