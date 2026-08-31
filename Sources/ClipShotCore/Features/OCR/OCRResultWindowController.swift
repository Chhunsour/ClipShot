import Foundation
import AppKit
import SwiftUI

/// Window controller for displaying OCR text recognition results.
public final class OCRResultWindowController: NSWindowController {
    public static var currentControllers: [OCRResultWindowController] = []

    public static func show(text: String, title: String = "Recognized Text") {
        let controller = OCRResultWindowController(text: text, windowTitle: title)
        currentControllers.append(controller)
        controller.showWindow(nil)
        controller.window?.center()
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    init(text: String, windowTitle: String) {
        let view = OCRResultView(text: text)
        let hostingController = NSHostingController(rootView: view)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 380),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "\(AppConfig.appName) — \(windowTitle)"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public struct OCRResultView: View {
    @State private var text: String
    @State private var copied: Bool = false
    @Environment(\.presentationMode) var presentationMode

    public init(text: String) {
        _text = State(initialValue: text)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "text.viewfinder")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("Extracted Text (OCR)")
                    .font(.headline)

                Spacer()

                Text("\(wordCount) words · \(text.count) chars")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .padding(6)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )

            HStack {
                Button("Close") {
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(action: copyToClipboard) {
                    HStack {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        Text(copied ? "Copied!" : "Copy All Text")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(minWidth: 420, minHeight: 320)
    }

    private var wordCount: Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return words.count
    }

    private func copyToClipboard() {
        ClipboardManager.shared.copyText(text)
        copied = true
        SoundManager.shared.playCopySound()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            copied = false
        }
    }
}
