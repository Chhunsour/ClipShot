import Foundation
import AppKit
import SwiftUI

/// Settings pane for ClipNotch customization, display selection, and real-time live preview.
public struct ClipNotchSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var displayTracker = DisplayTrackingService.shared
    @ObservedObject private var nowPlaying = SystemNowPlayingService.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPreviewingAnimation = false

    public var body: some View {
        Form {
            // Live Interactive Preview
            Section {
                VStack(spacing: 12) {
                    HStack {
                        Text("LIVE PREVIEW")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(1.0)

                        Spacer()

                        Button {
                            isPreviewingAnimation.toggle()
                        } label: {
                            Label(
                                isPreviewingAnimation ? "Stop preview" : "Preview animation",
                                systemImage: isPreviewingAnimation ? "stop.fill" : "play.fill"
                            )
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help("Preview the music animation without changing your settings")
                    }

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

                            let colorway = settings.clipNotchColorway
                            let finish = settings.clipNotchFinish
                            let motion = settings.clipNotchMotion

                            ZStack {
                                HStack(spacing: 5) {
                                    HStack(spacing: 2) {
                                        Image(systemName: "backward.fill")
                                        previewOrb(
                                            icon: "music.note",
                                            isSpectral: true,
                                            isAnimating: isPreviewingAnimation,
                                            colorway: colorway,
                                            motion: motion
                                        )
                                        Image(systemName: "forward.fill")
                                    }
                                    .font(.system(size: 6.5, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .padding(.horizontal, 4)
                                    .frame(height: 32)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(Color.white.opacity(isPreviewingAnimation ? finish.activeMediaRailFillOpacity : finish.inactiveMediaRailFillOpacity))
                                    )
                                    .overlay(
                                        Capsule(style: .continuous)
                                            .stroke(colorway.railGradient, lineWidth: 0.7)
                                            .opacity(isPreviewingAnimation ? finish.activeRailStrokeOpacity : finish.inactiveRailStrokeOpacity)
                                    )
                                    .shadow(
                                        color: colorway.primaryAccent.opacity(isPreviewingAnimation ? finish.activeMediaGlowOpacity : finish.inactiveMediaGlowOpacity),
                                        radius: finish.mediaGlowRadius
                                    )

                                    HStack(spacing: 6) {
                                        previewOrb(
                                            icon: "doc.on.clipboard",
                                            colorway: colorway,
                                            motion: motion
                                        )
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
                                    .padding(.horizontal, 5)
                                    .frame(height: 32)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(Color.white.opacity(finish.clipboardFillOpacity(isHovered: false)))
                                    )
                                    .overlay(
                                        Capsule(style: .continuous)
                                            .stroke(Color.white.opacity(finish.clipboardStrokeOpacity(isHovered: false)), lineWidth: 0.6)
                                    )
                                }
                                .padding(.horizontal, 11)
                                .opacity(settings.clipNotchIdleContent == .minimalIcon || isPreviewingAnimation ? 1 : 0)
                            }
                            .frame(
                                width: min(450, settings.clipNotchSize.idleDimensions.width),
                                height: settings.clipNotchSize.idleDimensions.height
                            )
                            .background(
                                ZStack {
                                    finish.outerBaseColor
                                    LinearGradient(
                                        colors: [
                                            finish.outerTopFill,
                                            finish.outerBaseColor,
                                            finish.outerBottomFill
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            colorway.primaryAccent.opacity(0.07 * finish.radialWashMultiplier),
                                            colorway.primaryAccent.opacity(0.07 * 0.35 * finish.radialWashMultiplier),
                                            Color.clear
                                        ]),
                                        center: UnitPoint(x: 0.5, y: 1.0),
                                        startRadius: 0,
                                        endRadius: 90
                                    )
                                }
                            )
                            .clipShape(previewClipShape)
                            .overlay {
                                if settings.clipNotchPlacementMode == .floatingIsland {
                                    previewClipShape
                                        .stroke(Color.white.opacity(finish.specularFloatingBorderOpacity), lineWidth: 0.75)
                                } else {
                                    previewClipShape
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.0),
                                                    Color.white.opacity(finish.specularBorderOpacity),
                                                    Color.white.opacity(finish.specularBorderOpacity * 1.6)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: 0.5
                                        )
                                }
                            }
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

            // Section: Look & Feel
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Palette Colorway")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 8)], spacing: 8) {
                        ForEach(ClipNotchColorway.allCases) { colorway in
                            let isSelected = settings.clipNotchColorway == colorway
                            Button {
                                settings.clipNotchColorway = colorway
                            } label: {
                                VStack(spacing: 4) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(colorway.swatchGradient)
                                            .frame(height: 22)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 0.75)
                                            )

                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 9, weight: .heavy))
                                                .foregroundStyle(.white)
                                                .shadow(color: .black.opacity(0.6), radius: 2)
                                        }
                                    }

                                    Text(colorway.rawValue)
                                        .font(.system(size: 9.5, weight: isSelected ? .bold : .regular))
                                        .foregroundColor(isSelected ? .primary : .secondary)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(isSelected ? Color.accentColor.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .help("\(colorway.rawValue) colorway")
                            .accessibilityLabel("\(colorway.rawValue) colorway\(isSelected ? ", selected" : "")")
                        }
                    }
                }
                .padding(.vertical, 2)

                Picker("Surface Finish", selection: $settings.clipNotchFinish) {
                    ForEach(ClipNotchFinish.allCases) { finish in
                        Text(finish.rawValue).tag(finish)
                    }
                }

                Picker("Motion Personality", selection: $settings.clipNotchMotion) {
                    ForEach(ClipNotchMotion.allCases) { motion in
                        Text(motion.rawValue).tag(motion)
                    }
                }

                Text("Changes update the live notch immediately.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Look & Feel")
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

    private func previewOrb(
        icon: String,
        isSpectral: Bool = false,
        isAnimating: Bool = false,
        colorway: ClipNotchColorway,
        motion: ClipNotchMotion
    ) -> some View {
        ZStack {
            if isSpectral {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 1.0)
                    .frame(width: 28, height: 28)

                Circle()
                    .trim(from: 0.0, to: 0.72)
                    .stroke(
                        colorway.orbGradient,
                        style: StrokeStyle(lineWidth: 1.3, lineCap: .round)
                    )
                    .frame(width: 28, height: 28)
                    .rotationEffect(.degrees(isAnimating && !reduceMotion ? 360 : 0))
                    .animation(
                        isAnimating && !reduceMotion
                            ? .linear(duration: motion.orbitDuration).repeatForever(autoreverses: false)
                            : .easeOut(duration: 0.25),
                        value: isAnimating && !reduceMotion
                    )
                    .opacity(isAnimating ? 1 : 0.4)
            }

            Image(systemName: icon)
                .font(.system(size: isSpectral ? 8 : 7.5, weight: isSpectral ? .semibold : .bold))
                .foregroundStyle(.white.opacity(0.88))
                .frame(width: isSpectral ? 22 : 23, height: isSpectral ? 22 : 23)
                .background(Circle().fill(.white.opacity(settings.clipNotchFinish.clipboardOrbFillOpacity(isHovered: false))))
                .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 0.6))
        }
        .frame(width: isSpectral ? 28 : 23, height: isSpectral ? 28 : 23)
    }

}
