import Foundation
import AppKit
import SwiftUI

public final class OnboardingWindowController: NSWindowController {
    public static let shared = OnboardingWindowController()

    public init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 380),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to \(AppConfig.appName)"
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)

        let hostingController = NSHostingController(
            rootView: OnboardingView(onComplete: { [weak self] in
                self?.close()
            })
        )
        window.contentViewController = hostingController
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func showOnboardingIfNeeded() {
        if !AppSettings.shared.hasCompletedOnboarding {
            showWindow(nil)
            window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

public struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var currentStep: Int = 1
    @State private var detectedFolder: URL = PathUtils.shared.activeScreenshotFolder()
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public var body: some View {
        VStack(spacing: 20) {
            if currentStep == 1 {
                step1Welcome
            } else if currentStep == 2 {
                step2Folder
            } else {
                step3Ready
            }
        }
        .padding(32)
        .frame(width: 480, height: 380)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Step 1: Welcome
    private var step1Welcome: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 56))
                .foregroundColor(.accentColor)
                .padding(.bottom, 4)

            Text("Welcome to \(AppConfig.appName)")
                .font(.title2)
                .fontWeight(.bold)

            Text("Take a screenshot.\nPaste it immediately.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Text("Whenever you take a screenshot with macOS shortcuts, ClipShot puts it on your clipboard instantly.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)

            Spacer()

            Button("Continue") {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) { currentStep = 2 }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
    }

    // MARK: - Step 2: Folder
    private var step2Folder: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("Screenshot Folder")
                .font(.title2)
                .fontWeight(.bold)

            Text("ClipShot watches your screenshot folder so it can automatically copy new screenshots.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Detected Folder:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Image(systemName: "folder")
                        .foregroundColor(.accentColor)
                    Text(PathUtils.shared.displayPath(for: detectedFolder))
                        .font(.system(.body, design: .monospaced))
                    Spacer()
                }
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }
            .padding(.horizontal, 10)

            Spacer()

            HStack(spacing: 12) {
                Button("Choose Another Folder...") {
                    chooseFolder()
                }

                Button("Use This Folder") {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) { currentStep = 3 }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    // MARK: - Step 3: Ready
    private var step3Ready: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text("You're Ready!")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                Text("1. Take a screenshot with:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 6) {
                    KeyBadge("⌘")
                    KeyBadge("⇧")
                    KeyBadge("4")
                }

                Text("2. Then press:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 6) {
                    KeyBadge("⌘")
                    KeyBadge("V")
                }

                Text("in ChatGPT, Discord, Slack, Figma, or any app.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)

            Spacer()

            Button("Start \(AppConfig.appName)") {
                settings.hasCompletedOnboarding = true
                ScreenshotMonitor.shared.start()
                onComplete()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose Screenshot Folder"

        panel.begin { result in
            if result == .OK, let url = panel.url {
                PathUtils.shared.saveBookmark(for: url)
                detectedFolder = url
                ScreenshotMonitor.shared.restart()
            }
        }
    }
}

private struct KeyBadge: View {
    let key: String

    init(_ key: String) {
        self.key = key
    }

    var body: some View {
        Text(key)
            .font(.system(size: 15, weight: .semibold, design: .monospaced))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 1, x: 0, y: 1)
    }
}
