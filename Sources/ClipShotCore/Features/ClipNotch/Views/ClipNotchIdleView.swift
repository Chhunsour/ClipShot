import Foundation
import AppKit
import SwiftUI

/// Adaptive, feature-rich Apple-style notch supporting scalable toolbars, live music HUD, quick capture tools, and system stats.
public struct ClipNotchIdleView: View {
    let onClipboard: () -> Void

    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var clipboardManager = ClipboardHistoryManager.shared
    @ObservedObject private var nowPlaying = SystemNowPlayingService.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var hoveredControl: Control?
    @State private var isRotating = false
    @State private var musicHoverWorkItem: DispatchWorkItem?
    @State private var clockString = ""
    @State private var clockTimer: Timer?
    @State private var miniEqPhases: [CGFloat] = [0.4, 0.9, 0.6]
    @State private var eqTimer: Timer?

    private enum Control {
        case artwork
        case previous
        case next
        case clipboard
        case toolArea
        case toolRecord
        case toolOCR
        case toolColor
        case toolHistory
        case volume
    }

    public var body: some View {
        Group {
            if settings.clipNotchIdleContent == .minimalIcon {
                HStack(spacing: settings.clipNotchSize >= .ultraWide ? 8 : 5) {
                    mediaControls

                    // Quick Capture Tools on wider notch sizes
                    if settings.clipNotchSize >= .extraLarge {
                        quickToolsCapsule
                    }

                    // System HUD (Clock & Volume) on Ultra Wide and Studio sizes
                    if settings.clipNotchSize >= .ultraWide {
                        systemHUDCapsule
                    }

                    clipboardButton
                }
                .padding(.horizontal, settings.clipNotchSize >= .ultraWide ? 14 : 10)
            } else {
                Color.clear.frame(width: 1, height: 1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
        .onAppear {
            isRotating = true
            updateClock()
            startTimers()
        }
        .onDisappear {
            clockTimer?.invalidate()
            eqTimer?.invalidate()
        }
    }

    // MARK: - Media Controls Capsule (Left)

    private var mediaControls: some View {
        let colorway = settings.clipNotchColorway
        let finish = settings.clipNotchFinish

        return HStack(spacing: 3) {
            transportButton(
                icon: "backward.fill",
                label: "Previous track",
                command: .previous,
                control: .previous
            )

            mediaArtwork

            transportButton(
                icon: "forward.fill",
                label: "Next track",
                command: .next,
                control: .next
            )

            // Dynamic Song Title & Mini Equalizer for Large and above
            if settings.clipNotchSize >= .large {
                Button {
                    ClipNotchViewModel.shared.showMusicPlayer()
                } label: {
                    HStack(spacing: 4) {
                        miniEqualizerView(colorway: colorway)

                        VStack(alignment: .leading, spacing: 0) {
                            Text(nowPlaying.title.isEmpty ? (nowPlaying.hasMedia ? "Audio Playing" : "Music") : nowPlaying.title)
                                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.92))
                                .lineLimit(1)

                            if settings.clipNotchSize >= .ultraWide && !nowPlaying.artist.isEmpty {
                                Text(nowPlaying.artist)
                                    .font(.system(size: 7, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.45))
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: mediaTitleMaxWidth, alignment: .leading)
                    }
                    .padding(.trailing, 4)
                }
                .buttonStyle(.plain)
                .help("Open music player")
                .onHover { setHover(.artwork, active: $0) }
            }
        }
        .padding(.horizontal, 4)
        .frame(height: 32)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(nowPlaying.isPlaying ? finish.activeMediaRailFillOpacity : finish.inactiveMediaRailFillOpacity))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(colorway.railGradient, lineWidth: 0.7)
                .opacity(nowPlaying.isPlaying ? finish.activeRailStrokeOpacity : finish.inactiveRailStrokeOpacity)
        )
        .shadow(
            color: colorway.primaryAccent.opacity(nowPlaying.isPlaying ? finish.activeMediaGlowOpacity : finish.inactiveMediaGlowOpacity),
            radius: finish.mediaGlowRadius
        )
        .animation(reduceMotion ? nil : .smooth(duration: 0.35), value: nowPlaying.isPlaying)
        .onHover { hovering in
            if hovering {
                setHover(.artwork, active: true)
            }
        }
    }

    private var mediaTitleMaxWidth: CGFloat {
        switch settings.clipNotchSize {
        case .compact, .normal: return 0
        case .large: return 54
        case .extraLarge: return 72
        case .ultraWide: return 90
        case .studio: return 115
        }
    }

    private var mediaArtwork: some View {
        let colorway = settings.clipNotchColorway
        let motion = settings.clipNotchMotion

        return Button {
            ClipNotchViewModel.shared.toggleMusicPlayer()
        } label: {
            ZStack {
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
                    .rotationEffect(.degrees(isRotating && nowPlaying.isPlaying && !reduceMotion ? 360 : 0))
                    .animation(
                        nowPlaying.isPlaying && !reduceMotion
                            ? .linear(duration: motion.orbitDuration).repeatForever(autoreverses: false)
                            : .easeOut(duration: 0.25),
                        value: isRotating && nowPlaying.isPlaying && !reduceMotion
                    )
                    .opacity(nowPlaying.isPlaying ? 1 : (nowPlaying.hasMedia ? 0.45 : 0.22))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: nowPlaying.isPlaying)

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(hoveredControl == .artwork ? 0.15 : 0.08))
                        .frame(width: 22, height: 22)

                    if let artwork = nowPlaying.artwork {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 22, height: 22)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 8.5, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.72))
                    }

                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.55))
                            .frame(width: 22, height: 22)

                        Image(systemName: nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(ClipNotchColorway.softWhiteGlint.opacity(0.95))
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .opacity(hoveredControl == .artwork ? 1 : 0)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: hoveredControl == .artwork)
                }
                .frame(width: 22, height: 22)
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
            }
            .frame(width: 28, height: 28)
            .contentShape(Circle())
            .scaleEffect(hoveredControl == .artwork && !reduceMotion ? motion.musicOrbHoverScale : 1)
            .animation(reduceMotion ? nil : .spring(response: motion.springResponse, dampingFraction: motion.springDampingFraction), value: hoveredControl)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .help(mediaTooltip)
        .accessibilityLabel(nowPlaying.isPlaying ? "Open music player" : "Play media")
        .onHover { setHover(.artwork, active: $0) }
    }

    private func transportButton(
        icon: String,
        label: String,
        command: SystemMediaCommand,
        control: Control
    ) -> some View {
        let motion = settings.clipNotchMotion

        return Button {
            SystemMediaController.send(command)
        } label: {
            Image(systemName: icon)
                .font(.system(size: 6.5, weight: .semibold))
                .foregroundStyle(.white.opacity(hoveredControl == control ? 0.9 : 0.42))
                .frame(width: 15, height: 24)
                .contentShape(Rectangle())
                .scaleEffect(hoveredControl == control && !reduceMotion ? motion.transportHoverScale : 1)
                .animation(reduceMotion ? nil : .spring(response: motion.transportSpringResponse, dampingFraction: motion.transportSpringDamping), value: hoveredControl == control)
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
        .onHover { setHover(control, active: $0) }
    }

    // MARK: - Quick Tools Capsule (Center)

    private var quickToolsCapsule: some View {
        let finish = settings.clipNotchFinish
        return HStack(spacing: 3) {
            // Area Screenshot
            toolActionButton(
                icon: "camera.viewfinder",
                label: "Capture Area",
                control: .toolArea
            ) {
                CaptureOverlayController.shared.showOverlay(initialMode: .area)
            }

            // Screen Recording
            toolActionButton(
                icon: "record.circle",
                label: "Record Screen",
                control: .toolRecord
            ) {
                CaptureOverlayController.shared.showOverlay(initialMode: .record)
            }

            if settings.clipNotchSize >= .ultraWide {
                // OCR Extractor
                toolActionButton(
                    icon: "text.viewfinder",
                    label: "Extract OCR Text",
                    control: .toolOCR
                ) {
                    CaptureOverlayController.shared.showOverlay(initialMode: .ocr)
                }

                // Color Picker Eyedropper
                toolActionButton(
                    icon: "eyedropper.halffull",
                    label: "Color Picker",
                    control: .toolColor
                ) {
                    CaptureOverlayController.shared.showOverlay(initialMode: .colorPicker)
                }
            }

            if settings.clipNotchSize == .studio {
                // History
                toolActionButton(
                    icon: "clock.arrow.circlepath",
                    label: "History Shelf",
                    control: .toolHistory
                ) {
                    HistoryWindowController.shared.showHistory()
                }
            }
        }
        .padding(.horizontal, 4)
        .frame(height: 32)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(finish.activeMediaRailFillOpacity * 0.75))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.6)
        )
    }

    private func toolActionButton(
        icon: String,
        label: String,
        control: Control,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 8.5, weight: .semibold))
                .foregroundStyle(.white.opacity(hoveredControl == control ? 1.0 : 0.6))
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(Color.white.opacity(hoveredControl == control ? 0.15 : 0.0))
                )
                .scaleEffect(hoveredControl == control && !reduceMotion ? 1.15 : 1.0)
                .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7), value: hoveredControl == control)
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
        .onHover { setHover(control, active: $0) }
    }

    // MARK: - System HUD Capsule (Clock & Stats)

    private var systemHUDCapsule: some View {
        HStack(spacing: 5) {
            // Live Clock
            Text(clockString)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))

            // Live Volume HUD button
            Button {
                SystemMediaController.send(.playPause)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.white.opacity(hoveredControl == .volume ? 1.0 : 0.65))
            }
            .buttonStyle(.plain)
            .help("Audio output active")
            .onHover { setHover(.volume, active: $0) }
        }
        .padding(.horizontal, 6)
        .frame(height: 32)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }

    // MARK: - Clipboard Capsule (Right)

    private var clipboardButton: some View {
        let finish = settings.clipNotchFinish
        let motion = settings.clipNotchMotion
        let isHovered = hoveredControl == .clipboard

        return Button(action: onClipboard) {
            HStack(spacing: 6) {
                clipboardOrb

                if settings.clipNotchSize != .compact {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(clipboardTitle)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.86))
                            .lineLimit(1)
                        Text("Clipboard")
                            .font(.system(size: 7.5, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.34))
                    }
                    .frame(width: clipboardLabelWidth, alignment: .leading)
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 5)
            .frame(height: 32)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(finish.clipboardFillOpacity(isHovered: isHovered)))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(finish.clipboardStrokeOpacity(isHovered: isHovered)), lineWidth: 0.6)
            )
            .opacity(isHovered ? 1 : 0.88)
            .scaleEffect(isHovered && !reduceMotion ? motion.clipboardHoverScale : 1, anchor: .trailing)
            .animation(reduceMotion ? nil : .spring(response: motion.clipboardSpringResponse, dampingFraction: motion.clipboardSpringDamping), value: hoveredControl)
        }
        .buttonStyle(.plain)
        .help("Open clipboard and captures")
        .accessibilityLabel("Open clipboard and captures")
        .onHover { setHover(.clipboard, active: $0) }
    }

    private var clipboardLabelWidth: CGFloat {
        switch settings.clipNotchSize {
        case .compact: return 0
        case .normal: return 50
        case .large: return 58
        case .extraLarge: return 68
        case .ultraWide: return 74
        case .studio: return 84
        }
    }

    private var clipboardOrb: some View {
        let finish = settings.clipNotchFinish
        let isHovered = hoveredControl == .clipboard

        return ZStack {
            Circle().fill(.white.opacity(finish.clipboardOrbFillOpacity(isHovered: isHovered)))

            if let item = clipboardManager.currentItem,
               item.kind == .image,
               let preview = item.previewImage {
                Image(nsImage: preview)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 0.5))
            } else {
                Image(systemName: clipboardManager.currentItem?.kind == .text ? "text.alignleft" : "doc.on.clipboard")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.78))
            }
        }
        .frame(width: 24, height: 24)
        .overlay(Circle().stroke(.white.opacity(0.09), lineWidth: 0.6))
    }

    @ViewBuilder
    private func miniEqualizerView(colorway: ClipNotchColorway) -> some View {
        HStack(spacing: 1.5) {
            ForEach(0..<miniEqPhases.count, id: \.self) { idx in
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(colorway.railGradient)
                    .frame(width: 1.8, height: nowPlaying.isPlaying ? max(2.5, 9 * miniEqPhases[idx]) : 2.5)
            }
        }
        .frame(height: 10)
    }

    private var mediaTooltip: String {
        let action = nowPlaying.isPlaying ? "Pause" : "Play"
        if !nowPlaying.displayTitle.isEmpty {
            return "\(action): \(nowPlaying.displayTitle)"
        }
        return "\(action) media"
    }

    private var clipboardTitle: String {
        guard let item = clipboardManager.currentItem else { return "Nothing yet" }
        return item.kind == .image ? "Screenshot" : "Text copied"
    }

    private func setHover(_ control: Control, active: Bool) {
        if active {
            hoveredControl = control
            if control == .artwork || control == .previous || control == .next {
                musicHoverWorkItem?.cancel()
                let item = DispatchWorkItem { [weak viewModel = ClipNotchViewModel.shared] in
                    viewModel?.showMusicPlayer()
                }
                musicHoverWorkItem = item
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: item)
            }
        } else {
            if control == .artwork || control == .previous || control == .next {
                musicHoverWorkItem?.cancel()
            }
            if hoveredControl == control {
                hoveredControl = nil
            }
        }
    }

    private func startTimers() {
        clockTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateClock()
        }
        eqTimer = Timer.scheduledTimer(withTimeInterval: 0.22, repeats: true) { _ in
            if nowPlaying.isPlaying && !reduceMotion {
                miniEqPhases = (0..<3).map { _ in CGFloat.random(in: 0.3...1.0) }
            } else {
                miniEqPhases = [0.3, 0.3, 0.3]
            }
        }
    }

    private func updateClock() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        clockString = formatter.string(from: Date())
    }
}

