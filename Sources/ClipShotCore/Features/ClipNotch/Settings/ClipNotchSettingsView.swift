import Foundation
import AppKit
import SwiftUI

/// Settings pane for ClipNotch customization, display selection, and real-time live preview.
public struct ClipNotchSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var displayTracker = DisplayTrackingService.shared

    public var body: some View {
        Form {
            // Live Interactive Preview
            Section {
                VStack(spacing: 12) {
                    Text("LIVE PREVIEW")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.0)

                    ZStack(alignment: .top) {
                        // Simulated Screen Top Bezel
                        Rectangle()
                            .fill(Color(white: 0.15))
                            .frame(height: 70)
                            .cornerRadius(8)
                            .overlay(
                                VStack {
                                    Rectangle()
                                        .fill(Color(white: 0.25))
                                        .frame(height: 1)
                                    Spacer()
                                }
                            )

                        // Rendered Notch
                        VStack(spacing: 0) {
                            if settings.clipNotchPlacementMode == .floatingIsland {
                                Spacer().frame(height: 6)
                            } else if settings.clipNotchPlacementMode == .belowMenuBar {
                                Spacer().frame(height: 16)
                            }

                            ZStack {
                                if settings.clipNotchIdleContent == .minimalIcon {
                                    HStack(spacing: 7) {
                                        HStack(spacing: 3) {
                                            previewOrb(icon: "music.note")
                                            Image(systemName: "backward.fill")
                                            previewOrb(icon: "play.fill")
                                            Image(systemName: "forward.fill")
                                        }
                                        .font(.system(size: 6.5, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.5))

                                        previewDivider

                                        HStack(spacing: 6) {
                                            previewOrb(icon: "doc.on.clipboard")
                                            if settings.clipNotchSize != .compact {
                                                VStack(alignment: .leading, spacing: 0) {
                                                    Text("Text copied")
                                                        .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                                                        .foregroundStyle(.white.opacity(0.82))
                                                    Text("Clipboard")
                                                        .font(.system(size: 7, weight: .medium, design: .rounded))
                                                        .foregroundStyle(.white.opacity(0.34))
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 11)
                                }
                            }
                            .frame(
                                width: settings.clipNotchSize.idleDimensions.width,
                                height: settings.clipNotchSize.idleDimensions.height
                            )
                            .background(Color.black)
                            .clipShape(previewClipShape)
                            .shadow(
                                color: Color.black.opacity(settings.clipNotchPlacementMode != .floatingIsland ? 0.35 : 0.4),
                                radius: settings.clipNotchPlacementMode != .floatingIsland ? 5 : 8,
                                x: 0,
                                y: settings.clipNotchPlacementMode != .floatingIsland ? 2 : 4
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 8)
            }

            // Section 1: Master Toggle & Display
            Section {
                Toggle("Enable ClipNotch", isOn: $settings.clipNotchEnabled)
                    .font(.headline)

                if settings.clipNotchEnabled {
                    Picker("Target Display", selection: Binding(
                        get: { settings.clipNotchDisplayUUID ?? "main" },
                        set: { settings.clipNotchDisplayUUID = $0 == "main" ? nil : $0 }
                    )) {
                        Text("Main Display (Default)").tag("main")
                        ForEach(displayTracker.availableDisplays.filter { !$0.isMain }) { display in
                            Text(display.displayName).tag(display.id)
                        }
                    }

                    Toggle("Fallback to Main Display if target is disconnected", isOn: $settings.clipNotchFallbackToMain)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Display & Monitor Placement")
            }

            if settings.clipNotchEnabled {
                // Section 2: Placement & Geometry
                Section {
                    Picker("Placement Mode", selection: $settings.clipNotchPlacementMode) {
                        ForEach(ClipNotchPlacementMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }

                    Picker("Notch Size", selection: $settings.clipNotchSize) {
                        ForEach(ClipNotchSize.allCases) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }

                    Picker("Idle Content", selection: $settings.clipNotchIdleContent) {
                        ForEach(ClipNotchIdleContent.allCases) { content in
                            Text(content.rawValue).tag(content)
                        }
                    }

                    HStack {
                        Text("Vertical Offset:")
                        Slider(value: $settings.clipNotchVerticalOffset, in: 0...40, step: 1)
                        Text("\(Int(settings.clipNotchVerticalOffset)) px")
                            .frame(width: 45)
                    }
                } header: {
                    Text("Placement & Geometry")
                }

                // Section 3: Behavior
                Section {
                    Toggle("Expand an Empty Notch on Hover", isOn: $settings.clipNotchExpandOnHover)

                    HStack {
                        Text("Auto-collapse Delay:")
                        Slider(value: $settings.clipNotchAutoCollapseDuration, in: 2.0...10.0, step: 0.5)
                        Text(String(format: "%.1f s", settings.clipNotchAutoCollapseDuration))
                            .frame(width: 45)
                    }

                    Toggle("Show ClipNotch over Fullscreen Applications", isOn: $settings.clipNotchShowInFullscreen)
                } header: {
                    Text("Behavior")
                }

            }
        }
        .formStyle(.grouped)
        .padding(16)
    }

    private var previewClipShape: some Shape {
        if settings.clipNotchPlacementMode != .floatingIsland {
            return AnyShape(AppleNotchShape(
                bottomCornerRadius: settings.clipNotchSize.bottomCornerRadius,
                topWingRadius: settings.clipNotchSize.topWingRadius
            ))
        } else {
            return AnyShape(RoundedRectangle(cornerRadius: settings.clipNotchSize.bottomCornerRadius + 3, style: .continuous))
        }
    }

    private func previewOrb(icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 7.5, weight: .bold))
            .foregroundStyle(.white.opacity(0.88))
            .frame(width: 23, height: 23)
            .background(Circle().fill(.white.opacity(0.09)))
            .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 0.6))
    }

    private var previewDivider: some View {
        Capsule()
            .fill(.white.opacity(0.1))
            .frame(width: 1, height: 14)
    }
}
