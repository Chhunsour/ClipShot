import Foundation
import AppKit
import SwiftUI

/// Compact activity shelf inside ClipNotch displaying both recent clipboard entries and screenshot captures.
public struct ClipNotchRecentShelfView: View {
    let items: [ScreenshotItem]
    let onSelect: (ScreenshotItem) -> Void
    let onOpenHistory: () -> Void
    let onClose: () -> Void

    @ObservedObject private var clipboardManager = ClipboardHistoryManager.shared
    @State private var copiedItemId: UUID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public var body: some View {
        VStack(spacing: 8) {
            headerBar
            clipboardSection
            capturesSection
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var headerBar: some View {
        HStack(alignment: .center) {
            HStack(spacing: 5) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                Text("Activity Shelf")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()

            Button(action: onOpenHistory) {
                HStack(spacing: 3) {
                    Text("Open History")
                        .font(.system(size: 10, weight: .medium))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .help("Open full screenshot history")

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(3)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
            .buttonStyle(.plain)
            .help("Close shelf")
        }
        .padding(.horizontal, 2)
    }

    @ViewBuilder
    private var clipboardSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 9.5))
                        .foregroundColor(.white.opacity(0.6))
                    Text("Clipboard")
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                if !clipboardManager.items.isEmpty {
                    Button(action: {
                        clipboardManager.clearHistory()
                    }) {
                        Text("Clear")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .help("Clear clipboard history")
                }
            }
            .padding(.horizontal, 2)

            let clipItems = Array(clipboardManager.items.prefix(3))
            if clipItems.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.35))
                    Text("No recent clipboard items")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.white.opacity(0.45))
                    Spacer()
                }
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.white.opacity(0.04)))
            } else {
                HStack(spacing: 6) {
                    ForEach(clipItems) { item in
                        ClipboardHistoryItemCell(
                            item: item,
                            isCopied: copiedItemId == item.id,
                            onCopy: {
                                copyItem(item)
                            }
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var capturesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "camera")
                    .font(.system(size: 9.5))
                    .foregroundColor(.white.opacity(0.6))
                Text("Recent Captures")
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 2)

            let captureItems = Array(items.prefix(4))
            if captureItems.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.35))
                    Text("No recent captures")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.white.opacity(0.45))
                    Spacer()
                }
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.white.opacity(0.04)))
            } else {
                HStack(spacing: 7) {
                    ForEach(captureItems) { item in
                        RecentThumbnailCell(item: item) {
                            onSelect(item)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func copyItem(_ item: ClipboardHistoryItem) {
        let success = clipboardManager.copy(item)
        guard success else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.15)) {
            copiedItemId = item.id
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            await MainActor.run {
                if copiedItemId == item.id {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.15)) {
                        copiedItemId = nil
                    }
                }
            }
        }
    }
}

struct ClipboardHistoryItemCell: View {
    let item: ClipboardHistoryItem
    let isCopied: Bool
    let onCopy: () -> Void

    @State private var isHovered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onCopy) {
            cellContent
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 30)
                .background(cellBackground)
                .overlay(cellBorder)
                .scaleEffect(cellScale)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(tooltipText)
    }

    @ViewBuilder
    private var cellContent: some View {
        HStack(spacing: 6) {
            if isCopied {
                copiedContent
            } else {
                itemKindContent
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var copiedContent: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.green)
        Text("Copied!")
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundColor(.green)
            .lineLimit(1)
    }

    @ViewBuilder
    private var itemKindContent: some View {
        switch item.kind {
        case .text:
            textContent
        case .image:
            imageContent
        }
    }

    @ViewBuilder
    private var textContent: some View {
        Image(systemName: "doc.text")
            .font(.system(size: 10))
            .foregroundColor(.white.opacity(0.7))
        Text(displayText)
            .font(.system(size: 10, weight: .regular))
            .foregroundColor(.white.opacity(0.85))
            .lineLimit(1)
            .truncationMode(.tail)
    }

    @ViewBuilder
    private var imageContent: some View {
        if let preview = item.previewImage {
            Image(nsImage: preview)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 22, height: 22)
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        } else {
            Image(systemName: "photo")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.7))
        }
        Text("Image")
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundColor(.white.opacity(0.85))
            .lineLimit(1)
    }

    private var cellBackground: some View {
        let fillColor: Color
        if isCopied {
            fillColor = Color.green.opacity(0.15)
        } else if isHovered {
            fillColor = Color.white.opacity(0.16)
        } else {
            fillColor = Color.white.opacity(0.08)
        }
        return RoundedRectangle(cornerRadius: 6, style: .continuous).fill(fillColor)
    }

    private var cellBorder: some View {
        let strokeColor: Color
        if isCopied {
            strokeColor = Color.green.opacity(0.5)
        } else if isHovered {
            strokeColor = Color.white.opacity(0.28)
        } else {
            strokeColor = Color.white.opacity(0.1)
        }
        return RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(strokeColor, lineWidth: 0.75)
    }

    private var cellScale: CGFloat {
        if isHovered && !reduceMotion && !isCopied {
            return 1.02
        }
        return 1.0
    }

    private var displayText: String {
        guard let text = item.text else { return "" }
        let singleLine = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return singleLine.isEmpty ? "Empty" : singleLine
    }

    private var tooltipText: String {
        if isCopied { return "Restored to clipboard" }
        switch item.kind {
        case .text:
            let text = displayText
            let prefix = text.prefix(60)
            return prefix.count < text.count ? "\(prefix)... (Click to copy)" : "\(text) (Click to copy)"
        case .image:
            return "Image (Click to copy)"
        }
    }
}

struct RecentThumbnailCell: View {
    let item: ScreenshotItem
    let onSelect: () -> Void

    @State private var thumbnail: NSImage?
    @State private var isHovered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onSelect) {
            thumbnailContent
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .overlay(thumbnailBorder)
                .scaleEffect(isHovered && !reduceMotion ? 1.03 : 1.0)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .onAppear {
            thumbnail = HistoryManager.shared.loadThumbnail(for: item)
        }
        .help(item.fileName)
    }

    @ViewBuilder
    private var thumbnailContent: some View {
        if let thumb = thumbnail {
            Image(nsImage: thumb)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 58, height: 38)
                .clipped()
        } else {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 58, height: 38)
                .overlay {
                    Image(systemName: "photo")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.3))
                }
        }
    }

    private var thumbnailBorder: some View {
        let strokeColor = isHovered ? Color.accentColor : Color.white.opacity(0.18)
        let strokeWidth: CGFloat = isHovered ? 1.5 : 0.75
        return RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(strokeColor, lineWidth: strokeWidth)
    }
}
