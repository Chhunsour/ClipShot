import Foundation
import AppKit
import SwiftUI

/// Redesigned screenshot preview state in ClipNotch with Apple-style fluid layout.
public struct ClipNotchScreenshotView: View {
    let item: ScreenshotItem
    let image: NSImage
    let onEdit: () -> Void
    let onOCR: () -> Void
    let onPin: () -> Void
    let onClose: () -> Void

    public var body: some View {
        HStack(spacing: 14) {
            // Clipped Thumbnail (Draggable with tactile spring hover)
            DraggableThumbnail(image: image, item: item)

            // Metadata & Actions
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("Screenshot copied")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.green)

                    Spacer()

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(4)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    .buttonStyle(.plain)
                }

                Text(item.fileName)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.white.opacity(0.65))
                    .lineLimit(1)

                // Action Buttons
                HStack(spacing: 5) {
                    NotchSmallPillButton(title: "Edit", icon: "pencil.tip.crop.circle", action: onEdit)
                    NotchSmallPillButton(title: "OCR", icon: "text.viewfinder", action: onOCR)
                    NotchSmallPillButton(title: "Pin", icon: "pin.fill", action: onPin)

                    Menu {
                        Button("Reveal in Finder") {
                            if let url = item.effectiveImageURL {
                                NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
                            }
                        }
                        Button("Share...") {
                            if let url = item.effectiveImageURL, let window = NSApp.keyWindow {
                                let picker = NSSharingServicePicker(items: [url])
                                picker.show(relativeTo: .zero, of: window.contentView ?? NSView(), preferredEdge: .minY)
                            }
                        }
                        Divider()
                        Button("Move to Trash", role: .destructive) {
                            if let url = item.effectiveImageURL {
                                try? FileManager.default.trashItem(at: url, resultingItemURL: nil)
                                HistoryManager.shared.trashOriginalFile(for: item)
                                onClose()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 24, height: 22)
                            .background(Color.white.opacity(0.14))
                            .cornerRadius(5)
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 24, height: 22)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minWidth: 350, maxWidth: 390)
        .transition(.opacity)
    }
}

struct DraggableThumbnail: View {
    let image: NSImage
    let item: ScreenshotItem

    @State private var isHovered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 86, height: 60)
            .background(Color.black.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isHovered ? Color.white.opacity(0.35) : Color.white.opacity(0.18), lineWidth: 1)
            )
            .scaleEffect(isHovered && !reduceMotion ? 1.02 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: isHovered)
            .onHover { isHovered = $0 }
            .onDrag {
                if let url = item.effectiveImageURL {
                    return NSItemProvider(object: url as NSURL)
                }
                return NSItemProvider()
            }
            .help("Drag screenshot")
    }
}

struct NotchSmallPillButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    @State private var isHovered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9.5))
                Text(title)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(isHovered ? Color.white.opacity(0.24) : Color.white.opacity(0.14))
            )
            .scaleEffect(isHovered && !reduceMotion ? 1.025 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(title)
    }
}
