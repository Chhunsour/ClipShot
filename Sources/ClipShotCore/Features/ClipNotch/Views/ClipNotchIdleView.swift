import Foundation
import AppKit
import SwiftUI

/// Long, matte-black Apple-style notch with media and clipboard controls.
public struct ClipNotchIdleView: View {
    let onClipboard: () -> Void

    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var clipboardManager = ClipboardHistoryManager.shared
    @ObservedObject private var nowPlaying = SystemNowPlayingService.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hoveredControl: Control?

    private enum Control {
        case artwork
        case previous
        case play
        case next
        case clipboard
    }

    public var body: some View {
        Group {
            if settings.clipNotchIdleContent == .minimalIcon {
                HStack(spacing: 7) {
                    mediaControls
                    notchDivider
                    clipboardButton
                }
                .padding(.horizontal, 11)
            } else {
                Color.clear.frame(width: 1, height: 1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }

    private var mediaControls: some View {
        HStack(spacing: 2) {
            mediaArtwork

            transportButton(
                icon: "backward.fill",
                label: "Previous track",
                command: .previous,
                control: .previous
            )

            Button {
                if SystemMediaController.send(.playPause) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { nowPlaying.refresh() }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(.white.opacity(hoveredControl == .play ? 0.16 : 0.09))
                    Circle()
                        .stroke(.white.opacity(hoveredControl == .play ? 0.22 : 0.1), lineWidth: 0.6)
                    Image(systemName: nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundStyle(.white.opacity(0.94))
                        .offset(x: nowPlaying.isPlaying ? 0 : 0.5)
                }
                .frame(width: 25, height: 25)
                .scaleEffect(hoveredControl == .play && !reduceMotion ? 1.06 : 1)
                .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.78), value: hoveredControl)
            }
            .buttonStyle(.plain)
            .help(nowPlaying.isPlaying ? "Pause media" : "Play media")
            .accessibilityLabel(nowPlaying.isPlaying ? "Pause media" : "Play media")
            .onHover { setHover(.play, active: $0) }

            transportButton(
                icon: "forward.fill",
                label: "Next track",
                command: .next,
                control: .next
            )
        }
    }

    private var mediaArtwork: some View {
        ZStack {
            Circle().fill(.white.opacity(hoveredControl == .artwork ? 0.15 : 0.08))

            if let artwork = nowPlaying.artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 22, height: 22)
                    .clipShape(Circle())
            } else {
                Image(systemName: nowPlaying.hasMedia ? "music.note" : "play.fill")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .frame(width: 24, height: 24)
        .overlay(Circle().stroke(.white.opacity(0.12), lineWidth: 0.6))
        .scaleEffect(hoveredControl == .artwork && !reduceMotion ? 1.05 : 1)
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8), value: hoveredControl)
        .help(nowPlaying.displayTitle.isEmpty ? "No media playing" : nowPlaying.displayTitle)
        .accessibilityLabel(nowPlaying.displayTitle.isEmpty ? "No media playing" : nowPlaying.displayTitle)
        .onHover { setHover(.artwork, active: $0) }
    }

    private func transportButton(
        icon: String,
        label: String,
        command: SystemMediaCommand,
        control: Control
    ) -> some View {
        Button {
            SystemMediaController.send(command)
        } label: {
            Image(systemName: icon)
                .font(.system(size: 6.5, weight: .semibold))
                .foregroundStyle(.white.opacity(hoveredControl == control ? 0.9 : 0.42))
                .frame(width: 15, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
        .onHover { setHover(control, active: $0) }
    }

    private var clipboardButton: some View {
        Button(action: onClipboard) {
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
                    .frame(width: settings.clipNotchSize == .large ? 58 : 50, alignment: .leading)
                }
            }
            .contentShape(Rectangle())
            .opacity(hoveredControl == .clipboard ? 1 : 0.88)
            .scaleEffect(hoveredControl == .clipboard && !reduceMotion ? 1.025 : 1, anchor: .trailing)
            .animation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.82), value: hoveredControl)
        }
        .buttonStyle(.plain)
        .help("Open clipboard and captures")
        .accessibilityLabel("Open clipboard and captures")
        .onHover { setHover(.clipboard, active: $0) }
    }

    private var clipboardOrb: some View {
        ZStack {
            Circle().fill(.white.opacity(hoveredControl == .clipboard ? 0.14 : 0.075))

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

    private var notchDivider: some View {
        Capsule()
            .fill(.white.opacity(0.1))
            .frame(width: 1, height: 14)
            .accessibilityHidden(true)
    }

    private var clipboardTitle: String {
        guard let item = clipboardManager.currentItem else { return "Nothing yet" }
        return item.kind == .image ? "Screenshot" : "Text copied"
    }

    private func setHover(_ control: Control, active: Bool) {
        if active {
            hoveredControl = control
        } else if hoveredControl == control {
            hoveredControl = nil
        }
    }
}
