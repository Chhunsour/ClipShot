import Foundation
import AppKit
import SwiftUI

public final class SettingsWindowController: NSWindowController {
    public static let shared = SettingsWindowController()

    public init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "\(AppConfig.appName) Settings"
        window.center()
        window.setFrameAutosaveName("ClipShotSettingsWindow")
        window.isReleasedWhenClosed = false

        super.init(window: window)

        let hostingController = NSHostingController(rootView: SettingsView())
        window.contentViewController = hostingController
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func showSettings() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

public struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var launchManager = LaunchAtLoginManager.shared
    @ObservedObject private var permissionsManager = PermissionsManager.shared

    public var body: some View {
        TabView {
            GeneralSettingsTab(settings: settings, launchManager: launchManager)
                .tabItem { Label("General", systemImage: "gearshape") }

            ScreenshotsSettingsTab(settings: settings)
                .tabItem { Label("Screenshots", systemImage: "camera") }

            ClipboardSettingsTab(settings: settings)
                .tabItem { Label("Clipboard", systemImage: "doc.on.clipboard") }

            PreviewSettingsTab(settings: settings)
                .tabItem { Label("Preview", systemImage: "macwindow.badge.plus") }

            ClipNotchSettingsView()
                .tabItem { Label("ClipNotch", systemImage: "sparkles.tv") }

            HistorySettingsTab(settings: settings)
                .tabItem { Label("History", systemImage: "clock") }

            ShortcutsSettingsTab()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }

            PermissionsTab(permissions: permissionsManager)
                .tabItem { Label("Permissions", systemImage: "lock.shield") }

            AdvancedSettingsTab(settings: settings)
                .tabItem { Label("Advanced", systemImage: "slider.horizontal.3") }

            AboutSettingsTab()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .padding(16)
        .frame(width: 580, height: 440)
    }
}

// MARK: - Tabs

struct GeneralSettingsTab: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var launchManager: LaunchAtLoginManager

    var body: some View {
        Form {
            Section {
                Toggle("Launch ClipShot at login", isOn: Binding(
                    get: { launchManager.isEnabled },
                    set: { launchManager.setEnabled($0) }
                ))

                Toggle("Show menu-bar icon", isOn: $settings.showMenuBarIcon)
                Toggle("Show Dock icon", isOn: $settings.showDockIcon)
            }

            Section {
                Toggle("Play sound after copy", isOn: $settings.playSoundOnCopy)
                Toggle("Show notification on error", isOn: $settings.notifyOnError)
                Toggle("Automatically check screenshot folder", isOn: $settings.autoCheckScreenshotFolder)
            }

            Section {
                Picker("Appearance", selection: $settings.appearance) {
                    ForEach(AppearanceSetting.allCases) { app in
                        Text(app.title).tag(app)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .padding(12)
    }
}

struct ScreenshotsSettingsTab: View {
    @ObservedObject var settings: AppSettings
    @State private var activeFolder = PathUtils.shared.activeScreenshotFolder()

    var body: some View {
        Form {
            Section {
                Toggle("Auto-copy screenshots to clipboard", isOn: $settings.autoCopyEnabled)

                Toggle("Instant Paste", isOn: $settings.instantPasteEnabled)

                Text("Turns off macOS’s floating screenshot thumbnail so ClipShot can copy immediately. ClipNotch remains your preview.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Screenshot Folder")
                        .font(.headline)

                    HStack {
                        Text(PathUtils.shared.displayPath(for: activeFolder))
                            .font(.system(.body, design: .monospaced))
                            .lineLimit(1)
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)

                        Button("Choose Folder...") {
                            chooseFolder()
                        }

                        Button("Reset") {
                            settings.customScreenshotFolderPath = nil
                            settings.screenshotFolderBookmark = nil
                            activeFolder = PathUtils.shared.activeScreenshotFolder()
                            ScreenshotMonitor.shared.restart()
                        }
                        .disabled(settings.customScreenshotFolderPath == nil)
                    }
                }
            }

            Section {
                Picker("Detection Mode", selection: $settings.detectionMode) {
                    ForEach(DetectionMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section {
                Toggle("Clipboard Only Mode (Trash screenshot after copying)", isOn: $settings.clipboardOnlyMode)

                if !settings.clipboardOnlyMode {
                    Picker("After Auto-Copy", selection: $settings.afterCopyAction) {
                        ForEach(AfterCopyAction.allCases) { action in
                            Text(action.title).tag(action)
                        }
                    }
                    .pickerStyle(.menu)

                    if settings.afterCopyAction == .deleteAfterDelay {
                        Stepper("Delete after \(settings.deleteAfterDelaySeconds) seconds", value: $settings.deleteAfterDelaySeconds, in: 2...60)
                    }
                }
            }
        }
        .padding(12)
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Screenshot Folder"

        panel.begin { result in
            if result == .OK, let url = panel.url {
                PathUtils.shared.saveBookmark(for: url)
                activeFolder = url
                ScreenshotMonitor.shared.restart()
            }
        }
    }
}

struct ClipboardSettingsTab: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Picker("Clipboard Content", selection: $settings.clipboardMode) {
                    ForEach(ClipboardMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section {
                Toggle("Prefer PNG format", isOn: $settings.preferPNG)
                Toggle("Preserve image transparency", isOn: $settings.preserveTransparency)
                Toggle("Preserve original resolution (Retina)", isOn: $settings.preserveOriginalResolution)
            }
        }
        .padding(12)
    }
}

struct PreviewSettingsTab: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Toggle("Show floating preview after screenshot", isOn: $settings.showFloatingPreview)
            }

            if settings.showFloatingPreview {
                Section {
                    Slider(value: $settings.previewDuration, in: 1...15, step: 1) {
                        Text("Disappear after: \(Int(settings.previewDuration)) seconds")
                    }

                    Picker("Screen Position", selection: $settings.previewCorner) {
                        ForEach(PreviewCorner.allCases) { corner in
                            Text(corner.title).tag(corner)
                        }
                    }
                    .pickerStyle(.radioGroup)

                    Toggle("Pause disappearance while hovering", isOn: $settings.pausePreviewOnHover)
                }
            }
        }
        .padding(12)
    }
}

struct HistorySettingsTab: View {
    @ObservedObject var settings: AppSettings
    @State private var showingClearConfirmation = false

    var body: some View {
        Form {
            Section {
                Toggle("Enable screenshot history", isOn: $settings.historyEnabled)
            }

            if settings.historyEnabled {
                Section {
                    Picker("Keep maximum screenshots", selection: $settings.historyLimit) {
                        ForEach(HistoryLimit.allCases) { limit in
                            Text(limit.title).tag(limit)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Delete history older than", selection: $settings.historyRetention) {
                        ForEach(HistoryRetention.allCases) { ret in
                            Text(ret.title).tag(ret)
                        }
                    }
                    .pickerStyle(.menu)

                    Toggle("Store copies of deleted/clipboard-only screenshots", isOn: $settings.storeDeletedScreenshotCopies)
                }

                Section {
                    Button(role: .destructive, action: { showingClearConfirmation = true }) {
                        Text("Clear All Screenshot History...")
                    }
                }
            }
        }
        .padding(12)
        .confirmationDialog(
            "Clear Screenshot History?",
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear History", role: .destructive) {
                HistoryManager.shared.clearHistory()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct ShortcutsSettingsTab: View {
    var body: some View {
        Form {
            Section(header: Text("Global Keyboard Shortcuts")) {
                ShortcutRow(title: "Capture Area", defaultKeys: "⌘ ⇧ 4 (macOS Native)")
                ShortcutRow(title: "Capture Full Screen", defaultKeys: "⌘ ⇧ 3 (macOS Native)")
                ShortcutRow(title: "Capture Window", defaultKeys: "⌘ ⇧ 4 Space")
                ShortcutRow(title: "Copy Last Screenshot", defaultKeys: "Customizable")
                ShortcutRow(title: "Open History", defaultKeys: "Customizable")
                ShortcutRow(title: "OCR Last Screenshot", defaultKeys: "Customizable")
                ShortcutRow(title: "Pin Last Screenshot", defaultKeys: "Customizable")
            }
        }
        .padding(12)
    }
}

struct ShortcutRow: View {
    let title: String
    let defaultKeys: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(defaultKeys)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(5)
        }
    }
}

struct PermissionsTab: View {
    @ObservedObject var permissions: PermissionsManager

    var body: some View {
        Form {
            Section(header: Text("System Permissions")) {
                PermissionStatusRow(
                    name: "Screenshot Folder",
                    granted: permissions.hasFolderAccess,
                    detail: "Required to detect and read screenshot files",
                    action: { permissions.openFolderAccessSettings() }
                )

                PermissionStatusRow(
                    name: "Screen Recording",
                    granted: permissions.hasScreenRecordingAccess,
                    detail: "Optional: Only needed for built-in capture actions",
                    action: { permissions.openScreenRecordingSettings() }
                )

                PermissionStatusRow(
                    name: "Notifications",
                    granted: permissions.hasNotificationAccess,
                    detail: "Used for copy feedback and error notifications",
                    action: { permissions.openNotificationSettings() }
                )
            }
        }
        .padding(12)
        .onAppear {
            permissions.checkAllPermissions()
        }
    }
}

struct PermissionStatusRow: View {
    let name: String
    let granted: Bool
    let detail: String
    let action: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: granted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(granted ? .green : .orange)
                    Text(name)
                        .fontWeight(.medium)
                }
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Settings...") {
                action()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}

struct AdvancedSettingsTab: View {
    @ObservedObject var settings: AppSettings
    @State private var showingResetConfirmation = false

    var body: some View {
        Form {
            Section {
                Picker("Detection Sensitivity", selection: $settings.detectionSensitivity) {
                    ForEach(DetectionSensitivity.allCases) { sens in
                        Text(sens.title).tag(sens)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section {
                Toggle("Ignore images modified long after creation", isOn: $settings.ignoreImagesModifiedAfterCreation)
                Toggle("Retry screenshot metadata detection", isOn: $settings.retryMetadataDetection)
            }

            Section {
                HStack {
                    Button("Open Log Folder") {
                        AppLogger.shared.openLogFolder()
                    }

                    Spacer()

                    Button(role: .destructive, action: { showingResetConfirmation = true }) {
                        Text("Reset All Settings...")
                    }
                }
            }
        }
        .padding(12)
        .confirmationDialog(
            "Reset ClipShot Settings?",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset All Settings", role: .destructive) {
                settings.resetToDefaults()
                ScreenshotMonitor.shared.restart()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct AboutSettingsTab: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "camera.viewfinder")
                .font(.system(size: 52))
                .foregroundColor(.accentColor)

            VStack(spacing: 4) {
                Text(AppConfig.appName)
                    .font(.title)
                    .fontWeight(.bold)
                Text("Version \(AppConfig.appVersion) (Build \(AppConfig.buildNumber))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 6) {
                Text("Instant screenshot-to-clipboard productivity utility.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("ClipShot processes screenshots 100% locally on your Mac.\nNo analytics. No cloud. Nothing leaves your computer.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
            }

            Text(AppConfig.copyright)
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.8))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
