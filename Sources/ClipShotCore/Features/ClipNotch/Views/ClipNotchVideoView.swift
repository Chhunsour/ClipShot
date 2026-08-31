import Foundation
import AppKit
import SwiftUI

public struct ClipNotchVideoView: View {
    let model: VideoCapsuleModel
    let onStop: () -> Void
    let onTogglePopOut: () -> Void

    @ObservedObject private var streamService = VideoCapsuleStreamService.shared
    @State private var isHovered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var activeModel: VideoCapsuleModel {
        streamService.activeModel ?? model
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            VideoCapsuleFrame(
                frame: streamService.currentFrame,
                scalingMode: activeModel.scalingMode,
                emptyMessage: streamService.streamError ?? "Connecting to \(activeModel.appName)…"
            )
            .padding(6)

            if isHovered {
                controls
                    .transition(.opacity)
            }
        }
        .onHover { hovering in
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
                isHovered = hovering
            }
        }
        .onTapGesture(count: 2, perform: onTogglePopOut)
    }

    private var controls: some View {
        HStack(spacing: 7) {
            Text(activeModel.displayTitle)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer(minLength: 4)

            Button {
                SystemMediaController.send(.playPause)
            } label: {
                VideoControlIcon(systemName: "playpause.fill")
            }
            .buttonStyle(.plain)
            .help("Play or pause media")

            Menu {
                ForEach(VideoScalingMode.allCases.filter { $0 != .original }) { mode in
                    Button {
                        streamService.updateScalingMode(mode)
                    } label: {
                        if activeModel.scalingMode == mode {
                            Label(mode.rawValue, systemImage: "checkmark")
                        } else {
                            Text(mode.rawValue)
                        }
                    }
                }
            } label: {
                VideoControlIcon(systemName: activeModel.scalingMode == .fill ? "rectangle.inset.filled" : "arrow.down.right.and.arrow.up.left")
            }
            .menuStyle(.borderlessButton)
            .help("Fit or fill")

            Menu {
                let windows = WindowCaptureService.shared.getVisibleWindows()
                if windows.isEmpty {
                    Text("No windows available")
                } else {
                    ForEach(windows) { window in
                        Button(window.displayName) {
                            streamService.switchSource(to: window)
                        }
                    }
                }
            } label: {
                VideoControlIcon(systemName: "rectangle.on.rectangle")
            }
            .menuStyle(.borderlessButton)
            .help("Change source")

            Menu {
                Button("Original") { streamService.cropToAspectRatio(nil) }
                Button("16:9") { streamService.cropToAspectRatio(16.0 / 9.0) }
                Button("Square") { streamService.cropToAspectRatio(1) }
            } label: {
                VideoControlIcon(systemName: "crop")
            }
            .menuStyle(.borderlessButton)
            .help("Crop")

            Button(action: onTogglePopOut) {
                VideoControlIcon(systemName: "pip.enter")
            }
            .buttonStyle(.plain)
            .help("Pop out")

            Button(action: onStop) {
                VideoControlIcon(systemName: "stop.fill", tint: .red)
            }
            .buttonStyle(.plain)
            .help("Stop video")
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(8)
    }
}

private struct VideoCapsuleFrame: View {
    let frame: CGImage?
    let scalingMode: VideoScalingMode
    let emptyMessage: String

    var body: some View {
        GeometryReader { geometry in
            if let frame {
                Image(decorative: frame, scale: 1)
                    .resizable()
                    .aspectRatio(contentMode: scalingMode == .fill ? .fill : .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            } else {
                VStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text(emptyMessage)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(white: 0.07))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct VideoControlIcon: View {
    let systemName: String
    var tint: Color = .white

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 22, height: 20)
            .background(Color.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
    }
}

@MainActor
public final class VideoCapsulePopOutController {
    public static let shared = VideoCapsulePopOutController()

    private var panel: NSPanel?

    public func show(model: VideoCapsuleModel) {
        if panel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
                styleMask: [.titled, .closable, .resizable, .utilityWindow],
                backing: .buffered,
                defer: false
            )
            panel.title = "Video Capsule"
            panel.level = .floating
            panel.isReleasedWhenClosed = false
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.minSize = NSSize(width: 280, height: 180)
            panel.center()
            self.panel = panel
        }

        panel?.contentView = NSHostingView(rootView: VideoCapsulePopOutView(
            fallbackModel: model,
            onStop: { [weak self] in
                ClipNotchViewModel.shared.stopVideo()
                self?.panel?.orderOut(nil)
            }
        ))
        panel?.orderFrontRegardless()
    }
}

private struct VideoCapsulePopOutView: View {
    let fallbackModel: VideoCapsuleModel
    let onStop: () -> Void

    @ObservedObject private var streamService = VideoCapsuleStreamService.shared

    private var activeModel: VideoCapsuleModel {
        streamService.activeModel ?? fallbackModel
    }

    var body: some View {
        VStack(spacing: 0) {
            VideoCapsuleFrame(
                frame: streamService.currentFrame,
                scalingMode: activeModel.scalingMode,
                emptyMessage: streamService.streamError ?? "Video source unavailable"
            )
            .padding(8)

            HStack {
                Text(activeModel.displayTitle)
                    .font(.caption)
                    .lineLimit(1)
                Spacer()
                Picker("Scaling", selection: Binding(
                    get: { activeModel.scalingMode },
                    set: { streamService.updateScalingMode($0) }
                )) {
                    Text("Fit").tag(VideoScalingMode.fit)
                    Text("Fill").tag(VideoScalingMode.fill)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 110)
                Button("Stop", role: .destructive, action: onStop)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .background(.black)
    }
}
