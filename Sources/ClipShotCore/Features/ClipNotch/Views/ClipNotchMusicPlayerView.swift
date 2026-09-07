import Foundation
import AppKit
import SwiftUI

/// Expanded high-fidelity music player card inside ClipNotch.
/// Engineered with premium Apple glass aesthetics, ambient artwork glow, live equalizer, duration scrubber, and volume control.
public struct ClipNotchMusicPlayerView: View {
    let onClose: () -> Void

    @ObservedObject private var nowPlaying = SystemNowPlayingService.shared
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isScrubbing = false
    @State private var isHoveringScrubber = false
    @State private var scrubbedPosition: Double = 0
    @State private var hoveredButton: ControlButton?
    @State private var equalizerPhases: [CGFloat] = [0.4, 0.9, 0.6, 0.8, 0.3]
    @State private var equalizerTimer: Timer?
    @State private var playbackOptions = SystemMediaPlaybackOptions.unavailable
    @State private var systemVolume: Double = 0.75
    @State private var isRevealed = false

    private enum ControlButton {
        case previous
        case rewind15
        case playPause
        case forward15
        case next
        case close
        case shuffle
        case `repeat`
        case favorite
        case volumeMute
        case volumeMax
    }

    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    private var currentDisplayPosition: Double {
        isScrubbing ? scrubbedPosition : nowPlaying.currentPosition
    }

    private var totalDuration: Double {
        nowPlaying.effectiveDuration
    }

    public var body: some View {
        let colorway = settings.clipNotchColorway
        let motion = settings.clipNotchMotion

        ZStack {
            if colorway == .albumAura {
                albumAuraBackdrop(colorway: colorway)
            }

            VStack(spacing: 8) {
                headerBar(colorway: colorway)
                trackInfoRow(colorway: colorway)
                scrubberSection(colorway: colorway)
                controlsRow(colorway: colorway, motion: motion)
                volumeSection(colorway: colorway)
            }
            .opacity(reduceMotion || isRevealed ? 1 : 0)
            .scaleEffect(x: reduceMotion || isRevealed ? 1 : 0.94, y: reduceMotion || isRevealed ? 1 : 0.82, anchor: .topLeading)
            .offset(x: reduceMotion || isRevealed ? 0 : -3, y: reduceMotion || isRevealed ? 0 : -3)
            .animation(reduceMotion ? nil : .spring(response: 0.12, dampingFraction: 0.88), value: isRevealed)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            startEqualizerAnimation()
            systemVolume = SystemMediaController.getVolume()
            refreshPlaybackOptions()
            if !reduceMotion {
                DispatchQueue.main.async { isRevealed = true }
            }
        }
        .onDisappear {
            equalizerTimer?.invalidate()
            isRevealed = false
        }
        .onChange(of: nowPlaying.title) { refreshPlaybackOptions() }
        .onChange(of: nowPlaying.sourceBundleIdentifier) { refreshPlaybackOptions() }
    }

    // MARK: - Subcomponents

    @ViewBuilder
    private func headerBar(colorway: ClipNotchColorway) -> some View {
        let badge = headerAppBadge
        HStack(spacing: 8) {
            // Live Dynamic App Badge
            HStack(spacing: 5) {
                equalizerVisualizer(colorway: colorway)

                Text(badge.title)
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(badge.tint)
                    .tracking(0.6)

                if nowPlaying.isPlaying {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 4.5, height: 4.5)
                        .shadow(color: .green.opacity(0.6), radius: 3)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3.5)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(badge.tint.opacity(0.3), lineWidth: 0.5)
            )

            Spacer()

            // Close / Collapse Button
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white.opacity(hoveredButton == .close ? 1.0 : 0.45))
                    .frame(width: 20, height: 20)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(hoveredButton == .close ? 0.14 : 0.05))
                    )
                    .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .help("Collapse music player (Esc)")
            .accessibilityLabel("Collapse music player")
            .onHover { hoveredButton = $0 ? .close : nil }
        }
    }

    private var headerAppBadge: (title: String, tint: Color) {
        switch nowPlaying.sourceBundleIdentifier {
        case "com.spotify.client":
            return ("SPOTIFY", Color(red: 29 / 255, green: 185 / 255, blue: 84 / 255))
        case "com.apple.Music":
            return ("APPLE MUSIC", Color(red: 250 / 255, green: 45 / 255, blue: 72 / 255))
        case "com.apple.podcasts":
            return ("PODCASTS", Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255))
        default:
            let title = nowPlaying.sourceAppName.isEmpty
                ? (nowPlaying.hasMedia ? "NOW PLAYING" : "SYSTEM AUDIO")
                : nowPlaying.sourceAppName.uppercased()
            return (title, settings.clipNotchColorway.primaryAccent)
        }
    }

    @ViewBuilder
    private func trackInfoRow(colorway: ClipNotchColorway) -> some View {
        HStack(spacing: 12) {
            // Artwork with ambient glow
            ZStack {
                if let artwork = nowPlaying.artwork {
                    if colorway == .albumAura {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 52, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .scaleEffect(1.28)
                            .blur(radius: 13)
                            .opacity(nowPlaying.isPlaying ? 0.48 : 0.22)
                    }

                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 0.75)
                        )
                        .shadow(color: colorway.primaryAccent.opacity(nowPlaying.isPlaying ? 0.45 : 0.12), radius: 8, x: 0, y: 2)
                } else {
                    // Fallback vinyl aesthetic with gentle rotation
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color(white: 0.22), Color(white: 0.08)],
                                    center: .center,
                                    startRadius: 2,
                                    endRadius: 25
                                )
                            )
                            .frame(width: 50, height: 50)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            )

                        Circle()
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                            .frame(width: 34, height: 34)

                        Circle()
                            .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                            .frame(width: 22, height: 22)

                        Image(systemName: "music.note")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(colorway.primaryAccent.opacity(0.9))
                    }
                    .shadow(color: colorway.primaryAccent.opacity(nowPlaying.isPlaying ? 0.35 : 0.1), radius: 6, x: 0, y: 2)
                }
            }

            // Text Metadata
            VStack(alignment: .leading, spacing: 2) {
                Text(nowPlaying.title.isEmpty ? (nowPlaying.hasMedia ? "Audio Playing" : "No Track Selected") : nowPlaying.title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(nowPlaying.artist.isEmpty ? "System Media" : nowPlaying.artist)
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(1)

                Text(nowPlaying.album.isEmpty ? (nowPlaying.isPlaying ? "Playing" : "Paused") : nowPlaying.album)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
                    .lineLimit(1)
            }

            Spacer(minLength: 4)
        }
    }

    @ViewBuilder
    private func scrubberSection(colorway: ClipNotchColorway) -> some View {
        VStack(spacing: 3) {
            scrubberBar(colorway: colorway)

            HStack {
                Text(formatTime(currentDisplayPosition))
                    .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.55))

                Spacer()

                Text(formatTime(totalDuration))
                    .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }

    @ViewBuilder
    private func controlsRow(colorway: ClipNotchColorway, motion: ClipNotchMotion) -> some View {
        HStack(spacing: 14) {
            if playbackOptions.shuffleAvailable {
                Button {
                    toggle(.shuffle)
                } label: {
                    Image(systemName: "shuffle")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(playbackOptions.shuffle ? colorway.primaryAccent : .white.opacity(0.45))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .help("Toggle shuffle")
                .accessibilityLabel("Toggle shuffle")
            }

            // Previous track
            Button {
                SystemMediaController.send(.previous)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { nowPlaying.refresh() }
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(hoveredButton == .previous ? 1.0 : 0.72))
                    .frame(width: 24, height: 24)
                    .scaleEffect(hoveredButton == .previous && !reduceMotion ? motion.transportHoverScale : 1.0)
            }
            .buttonStyle(.plain)
            .help("Previous track")
            .onHover { hoveredButton = $0 ? .previous : nil }

            // Rewind 15s
            Button {
                nowPlaying.skip(seconds: -15)
            } label: {
                Image(systemName: "gobackward.15")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(hoveredButton == .rewind15 ? 1.0 : 0.72))
                    .frame(width: 22, height: 22)
                    .scaleEffect(hoveredButton == .rewind15 && !reduceMotion ? 1.1 : 1.0)
            }
            .buttonStyle(.plain)
            .help("Rewind 15 seconds")
            .onHover { hoveredButton = $0 ? .rewind15 : nil }

            // Main Play/Pause Button
            Button {
                if SystemMediaController.send(.playPause) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { nowPlaying.refresh() }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(colorway.controlGradient)
                        .frame(width: 35, height: 35)
                        .shadow(color: colorway.primaryAccent.opacity(0.45), radius: 6)

                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        .frame(width: 35, height: 35)

                    Image(systemName: nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                }
                .scaleEffect(hoveredButton == .playPause && !reduceMotion ? 1.06 : 1.0)
            }
            .buttonStyle(.plain)
            .help(nowPlaying.isPlaying ? "Pause" : "Play")
            .onHover { hoveredButton = $0 ? .playPause : nil }

            // Fast Forward 15s
            Button {
                nowPlaying.skip(seconds: 15)
            } label: {
                Image(systemName: "goforward.15")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(hoveredButton == .forward15 ? 1.0 : 0.72))
                    .frame(width: 22, height: 22)
                    .scaleEffect(hoveredButton == .forward15 && !reduceMotion ? 1.1 : 1.0)
            }
            .buttonStyle(.plain)
            .help("Skip forward 15 seconds")
            .onHover { hoveredButton = $0 ? .forward15 : nil }

            // Next track
            Button {
                SystemMediaController.send(.next)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { nowPlaying.refresh() }
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(hoveredButton == .next ? 1.0 : 0.72))
                    .frame(width: 24, height: 24)
                    .scaleEffect(hoveredButton == .next && !reduceMotion ? motion.transportHoverScale : 1.0)
            }
            .buttonStyle(.plain)
            .help("Next track")
            .onHover { hoveredButton = $0 ? .next : nil }

            if playbackOptions.repeatAvailable {
                Button {
                    toggle(.repeatMode)
                } label: {
                    Image(systemName: "repeat")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(playbackOptions.repeatEnabled ? colorway.primaryAccent : .white.opacity(0.45))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .help("Toggle repeat")
                .accessibilityLabel("Toggle repeat")
            }

            if playbackOptions.favoriteAvailable {
                Button {
                    toggle(.favorite)
                } label: {
                    Image(systemName: playbackOptions.favorite ? "heart.fill" : "heart")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(playbackOptions.favorite ? Color.red : .white.opacity(0.45))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .help("Toggle favorite")
                .accessibilityLabel("Toggle favorite")
            }
        }
    }

    @ViewBuilder
    private func volumeSection(colorway: ClipNotchColorway) -> some View {
        HStack(spacing: 8) {
            Button {
                let newVol = systemVolume > 0 ? 0.0 : 0.5
                systemVolume = newVol
                SystemMediaController.setVolume(newVol)
            } label: {
                Image(systemName: systemVolume == 0 ? "speaker.slash.fill" : "speaker.fill")
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundStyle(.white.opacity(hoveredButton == .volumeMute ? 1.0 : 0.45))
                    .frame(width: 14, height: 14)
            }
            .buttonStyle(.plain)
            .help(systemVolume == 0 ? "Unmute" : "Mute")
            .onHover { hoveredButton = $0 ? .volumeMute : nil }

            GeometryReader { volProxy in
                let volWidth = volProxy.size.width
                let thumbX = volWidth * CGFloat(systemVolume)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 3.5)

                    Capsule()
                        .fill(colorway == .albumAura ? colorway.primaryAccent.opacity(0.88) : Color.white.opacity(0.7))
                        .frame(width: max(3.5, thumbX), height: 3.5)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 8.5, height: 8.5)
                        .shadow(color: .black.opacity(0.35), radius: 2)
                        .offset(x: max(0, min(volWidth - 8.5, thumbX - 4.25)))
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { val in
                            let clamped = max(0, min(1.0, Double(val.location.x / volWidth)))
                            systemVolume = clamped
                            SystemMediaController.setVolume(clamped)
                        }
                )
            }
            .frame(height: 10)

            Button {
                systemVolume = 1.0
                SystemMediaController.setVolume(1.0)
            } label: {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundStyle(.white.opacity(hoveredButton == .volumeMax ? 1.0 : 0.45))
                    .frame(width: 14, height: 14)
            }
            .buttonStyle(.plain)
            .help("Max Volume")
            .onHover { hoveredButton = $0 ? .volumeMax : nil }

            Text("\(Int(systemVolume * 100))%")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 24, alignment: .trailing)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Scrubber Component

    @ViewBuilder
    private func scrubberBar(colorway: ClipNotchColorway) -> some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let progress = totalDuration > 0 ? min(1.0, max(0.0, currentDisplayPosition / totalDuration)) : 0
            let thumbX = width * CGFloat(progress)

            ZStack(alignment: .leading) {
                // Background Track
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 4)

                // Filled Progress Bar
                Capsule()
                    .fill(colorway.railGradient)
                    .frame(width: max(4, thumbX), height: 4)
                    .shadow(color: colorway.primaryAccent.opacity(isScrubbing ? 0.6 : 0.2), radius: 4)

                // Draggable Thumb Knob (expands gracefully on scrub / hover)
                Circle()
                    .fill(Color.white)
                    .frame(width: isScrubbing || isHoveringScrubber ? 11 : 7.5, height: isScrubbing || isHoveringScrubber ? 11 : 7.5)
                    .overlay(Circle().stroke(colorway.primaryAccent.opacity(0.6), lineWidth: 1.0))
                    .shadow(color: Color.black.opacity(0.4), radius: 2.5, x: 0, y: 1)
                    .offset(x: max(0, min(width - (isScrubbing || isHoveringScrubber ? 11 : 7.5), thumbX - (isScrubbing || isHoveringScrubber ? 5.5 : 3.75))))
                    .animation(reduceMotion ? nil : .spring(response: 0.2, dampingFraction: 0.7), value: isScrubbing || isHoveringScrubber)

                // Floating Scrub Tooltip Pill
                if isScrubbing {
                    Text(formatTime(scrubbedPosition))
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.black.opacity(0.85))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                        )
                        .offset(x: max(0, min(width - 32, thumbX - 16)), y: -16)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .contentShape(Rectangle())
            .onHover { isHoveringScrubber = $0 }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isScrubbing = true
                        let clampedX = max(0, min(width, value.location.x))
                        let ratio = width > 0 ? Double(clampedX / width) : 0
                        scrubbedPosition = ratio * totalDuration
                    }
                    .onEnded { value in
                        let clampedX = max(0, min(width, value.location.x))
                        let ratio = width > 0 ? Double(clampedX / width) : 0
                        let target = ratio * totalDuration
                        nowPlaying.seek(to: target)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isScrubbing = false
                        }
                    }
            )
        }
        .frame(height: 12)
        .allowsHitTesting(totalDuration > 0)
        .opacity(totalDuration > 0 ? 1 : 0.45)
    }

    // MARK: - Animated Equalizer Visualizer

    @ViewBuilder
    private func equalizerVisualizer(colorway: ClipNotchColorway) -> some View {
        HStack(spacing: 1.8) {
            ForEach(0..<equalizerPhases.count, id: \.self) { idx in
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(colorway.railGradient)
                    .frame(width: 2, height: nowPlaying.isPlaying ? max(2.5, 9 * equalizerPhases[idx]) : 2.5)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: equalizerPhases[idx])
            }
        }
        .frame(height: 10)
    }

    private func startEqualizerAnimation() {
        equalizerTimer = Timer.scheduledTimer(withTimeInterval: 0.18, repeats: true) { _ in
            if nowPlaying.isPlaying && !reduceMotion {
                equalizerPhases = (0..<5).map { _ in CGFloat.random(in: 0.25...1.0) }
            } else {
                equalizerPhases = [0.3, 0.3, 0.3, 0.3, 0.3]
            }
        }
    }

    private func refreshPlaybackOptions() {
        SystemMediaController.playbackOptions(for: nowPlaying.sourceBundleIdentifier) { playbackOptions = $0 }
    }

    private func toggle(_ option: SystemMediaOption) {
        SystemMediaController.toggle(option, for: nowPlaying.sourceBundleIdentifier) { newValue in
            guard newValue != nil else { return }
            refreshPlaybackOptions()
        }
    }

    private func albumAuraBackdrop(colorway: ClipNotchColorway) -> some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .fill(colorway.primaryAccent.opacity(nowPlaying.isPlaying ? 0.20 : 0.10))
                    .frame(width: 170, height: 170)
                    .blur(radius: 34)
                    .offset(x: -52, y: -34)

                Ellipse()
                    .fill(colorway.secondaryAccent.opacity(nowPlaying.isPlaying ? 0.12 : 0.06))
                    .frame(width: proxy.size.width * 0.72, height: 96)
                    .blur(radius: 38)
                    .offset(x: proxy.size.width * 0.18, y: proxy.size.height * 0.42)
            }
            .opacity(reduceMotion || isRevealed ? 1 : 0)
            .scaleEffect(reduceMotion || isRevealed ? 1 : 0.72, anchor: .topLeading)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.10), value: isRevealed)
        }
        .allowsHitTesting(false)
    }

    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite && seconds >= 0 else { return "0:00" }
        let total = Int(seconds)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
