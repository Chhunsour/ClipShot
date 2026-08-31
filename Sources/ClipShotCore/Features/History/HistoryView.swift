import Foundation
import AppKit
import SwiftUI

public final class HistoryWindowController: NSWindowController {
    public static let shared = HistoryWindowController()

    public init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 540),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "\(AppConfig.appName) — Screenshot History"
        window.center()
        window.setFrameAutosaveName("ClipShotHistoryWindow")
        window.isReleasedWhenClosed = false

        super.init(window: window)

        let hostingController = NSHostingController(rootView: HistoryView())
        window.contentViewController = hostingController
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func showHistory() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

public struct HistoryView: View {
    @ObservedObject private var historyManager = HistoryManager.shared
    @State private var searchText: String = ""
    @State private var showingClearConfirmation = false
    @State private var selectedItem: ScreenshotItem?
    @State private var isGridView: Bool = false

    private var filteredItems: [ScreenshotItem] {
        if searchText.isEmpty {
            return historyManager.items
        }
        return historyManager.items.filter {
            $0.fileName.localizedCaseInsensitiveContains(searchText) ||
            $0.dimensionsString.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedSections: [(title: String, items: [ScreenshotItem])] {
        let grouped = Dictionary(grouping: filteredItems) { $0.sectionTitle }
        let sortedKeys = grouped.keys.sorted { k1, k2 in
            if k1 == "Today" { return true }
            if k2 == "Today" { return false }
            if k1 == "Yesterday" { return true }
            if k2 == "Yesterday" { return false }
            return k1 > k2
        }
        return sortedKeys.compactMap { key in
            guard let items = grouped[key] else { return nil }
            return (title: key, items: items.sorted { $0.createdAt > $1.createdAt })
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Search & Actions
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search history...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(6)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)

                // Grid / List toggle
                Picker("", selection: $isGridView) {
                    Image(systemName: "list.bullet").tag(false)
                    Image(systemName: "square.grid.2x2").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 70)

                Spacer()

                Text("\(filteredItems.count) screenshots")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button(role: .destructive, action: { showingClearConfirmation = true }) {
                    Label("Clear History", systemImage: "trash")
                }
                .disabled(historyManager.items.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Content List / Grid
            if filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text(searchText.isEmpty ? "No Screenshot History" : "No Matching Screenshots")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "Screenshots will automatically appear here." : "Try a different search term.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.underPageBackgroundColor))
            } else if isGridView {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)], spacing: 16) {
                        ForEach(filteredItems) { item in
                            HistoryItemGridCell(item: item)
                        }
                    }
                    .padding(16)
                }
                .background(Color(NSColor.underPageBackgroundColor))
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(groupedSections, id: \.title) { section in
                            Section(header: sectionHeader(section.title)) {
                                ForEach(section.items) { item in
                                    HistoryItemRow(item: item)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
                .background(Color(NSColor.underPageBackgroundColor))
            }
        }
        .confirmationDialog(
            "Clear Screenshot History?",
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All History", role: .destructive) {
                historyManager.clearHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all items from ClipShot history. Original files on disk will not be deleted.")
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.secondary)
            .padding(.vertical, 4)
    }
}

public struct HistoryItemRow: View {
    let item: ScreenshotItem
    @ObservedObject private var historyManager = HistoryManager.shared

    @State private var thumbnail: NSImage?
    @State private var isHovered = false

    public var body: some View {
        HStack(spacing: 14) {
            // Thumbnail
            ZStack {
                if let thumb = thumbnail {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 60)
                        .cornerRadius(6)
                } else {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 80, height: 60)
                        .cornerRadius(6)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        )
                }
            }
            .frame(width: 80, height: 60)

            // Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.fileName)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)

                    if item.isDeletedFromDisk {
                        Text("Moved to Trash")
                            .font(.system(size: 10))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.red.opacity(0.15))
                            .foregroundColor(.red)
                            .cornerRadius(3)
                    }
                }

                HStack(spacing: 12) {
                    Text(item.formattedTime)
                    Text("•")
                    Text(item.dimensionsString)
                    Text("•")
                    Text(item.formattedFileSize)
                }
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            }

            Spacer()

            // Actions
            HStack(spacing: 8) {
                Button(action: copyItem) {
                    Image(systemName: "doc.on.doc")
                }
                .help("Copy to Clipboard")

                Button(action: openOCR) {
                    Image(systemName: "text.viewfinder")
                }
                .help("Extract Text (OCR)")

                Button(action: openMarkup) {
                    Image(systemName: "pencil.tip.crop.circle")
                }
                .help("Edit & Annotate")

                Button(action: pinImage) {
                    Image(systemName: "pin")
                }
                .help("Pin Screenshot")

                Menu {
                    Button("Open in Default App") {
                        if let url = item.effectiveImageURL {
                            NSWorkspace.shared.open(url)
                        }
                    }

                    Button("Reveal in Finder") {
                        NSWorkspace.shared.selectFile(item.fileURL.path, inFileViewerRootedAtPath: item.fileURL.deletingLastPathComponent().path)
                    }

                    Button("Save As...") {
                        saveAs()
                    }

                    Divider()

                    Button("Delete from History") {
                        historyManager.deleteItem(item)
                    }

                    if !item.isDeletedFromDisk {
                        Button("Move File to Trash", role: .destructive) {
                            historyManager.trashOriginalFile(for: item)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
                .frame(width: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color(NSColor.selectedContentBackgroundColor).opacity(0.1) : Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
        .onHover { isHovered = $0 }
        .onAppear {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        thumbnail = historyManager.loadThumbnail(for: item)
    }

    private func copyItem() {
        if let url = item.effectiveImageURL, let img = ImageUtils.loadImage(at: url) {
            ClipboardManager.shared.copy(image: img, fileURL: url)
            SoundManager.shared.playCopySound()
        }
    }

    private func openOCR() {
        if let url = item.effectiveImageURL {
            Task {
                if let text = try? await OCRService.shared.recognizeText(from: url) {
                    await MainActor.run {
                        OCRResultWindowController.show(text: text, title: item.fileName)
                    }
                }
            }
        }
    }

    private func openMarkup() {
        if let url = item.effectiveImageURL, let img = ImageUtils.loadImage(at: url) {
            MarkupWindowController.open(image: img, sourceURL: url)
        }
    }

    private func pinImage() {
        if let url = item.effectiveImageURL, let img = ImageUtils.loadImage(at: url) {
            PinnedImageWindowController.pin(image: img, title: item.fileName)
        }
    }

    private func saveAs() {
        guard let url = item.effectiveImageURL, let img = ImageUtils.loadImage(at: url) else { return }
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = item.fileName

        savePanel.begin { result in
            if result == .OK, let saveURL = savePanel.url {
                try? ImageUtils.savePNG(image: img, to: saveURL)
            }
        }
    }
}

public struct HistoryItemGridCell: View {
    let item: ScreenshotItem
    @ObservedObject private var historyManager = HistoryManager.shared
    @State private var thumbnail: NSImage?
    @State private var isHovered = false

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                if let thumb = thumbnail {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: 110)
                        .cornerRadius(6)
                } else {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 110)
                        .cornerRadius(6)
                }
            }

            Text(item.fileName)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)

            HStack {
                Text(item.formattedTime)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer()
                Text(item.dimensionsString)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color(NSColor.selectedContentBackgroundColor).opacity(0.1) : Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
        .onHover { isHovered = $0 }
        .onAppear {
            thumbnail = historyManager.loadThumbnail(for: item)
        }
        .onTapGesture {
            if let url = item.effectiveImageURL, let img = ImageUtils.loadImage(at: url) {
                ClipboardManager.shared.copy(image: img, fileURL: url)
                SoundManager.shared.playCopySound()
            }
        }
    }
}
