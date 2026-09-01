import Foundation
import AppKit
import SwiftUI

/// Main hardware-integrated morphing container for ClipNotch with Apple-style fluid spring physics and concave bezel wings.
public struct ClipNotchView: View {
    @ObservedObject private var viewModel = ClipNotchViewModel.shared
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var displayTracker = DisplayTrackingService.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var hoverWorkItem: DispatchWorkItem?

    public var body: some View {
        ZStack {
            contentForState(viewModel.currentState)
                .id(viewModel.currentState.presentationKind)
                .transition(reduceMotion ? .opacity : .asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .top)),
                    removal: .opacity
                ))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(
            reduceMotion ? nil : .spring(
                response: settings.clipNotchMotion.springResponse,
                dampingFraction: settings.clipNotchMotion.springDampingFraction,
                blendDuration: 0.04
            ),
            value: viewModel.currentState.presentationKind
        )
        .background(notchBackground)
        .clipShape(notchClipShape)
        .overlay {
            let finish = settings.clipNotchFinish
            let colorway = settings.clipNotchColorway
            if finish == .neonAura {
                notchClipShape
                    .stroke(
                        LinearGradient(
                            colors: colorway.colors,
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1.0
                    )
            } else if settings.clipNotchPlacementMode == .floatingIsland {
                notchClipShape
                    .stroke(Color.white.opacity(finish.specularFloatingBorderOpacity), lineWidth: 0.75)
            } else {
                notchClipShape
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
            color: settings.clipNotchFinish == .neonAura ? settings.clipNotchColorway.primaryAccent.opacity(0.35) : (settings.clipNotchPlacementMode == .floatingIsland ? Color.black.opacity(0.45) : .clear),
            radius: settings.clipNotchFinish == .neonAura ? 12 : (settings.clipNotchPlacementMode == .floatingIsland ? 9 : 0),
            x: 0,
            y: settings.clipNotchPlacementMode == .floatingIsland ? 5 : 2
        )
        .onHover { hovering in
            handleHover(hovering)
        }
        .contextMenu {
            notchContextMenu
        }
    }

    @ViewBuilder
    private func contentForState(_ state: ClipNotchState) -> some View {
        switch state {
        case .idle:
            ClipNotchIdleView(
                onClipboard: { viewModel.showRecentShelf() }
            )

        case .quickActions:
            ClipNotchQuickActionsView(
                onArea: { CaptureOverlayController.shared.showOverlay(initialMode: .area) },
                onWindow: { CaptureOverlayController.shared.showOverlay(initialMode: .window) },
                onOCR: { CaptureOverlayController.shared.showOverlay(initialMode: .ocr) },
                onRecord: { CaptureOverlayController.shared.showOverlay(initialMode: .record) },
                onColor: { CaptureOverlayController.shared.showOverlay(initialMode: .colorPicker) },
                onMore: { viewModel.showRecentShelf() }
            )

        case .musicPlayer:
            ClipNotchMusicPlayerView(
                onClose: { viewModel.showIdle() }
            )

        case .screenshotPreview(let item, _):
            CopiedToastView(copyID: item.id)
                .id(item.id)

        case .video(let model):
            ClipNotchVideoView(
                model: model,
                onStop: {
                    viewModel.stopVideo()
                },
                onTogglePopOut: {
                    togglePopOutMiniPlayer(model: model)
                }
            )

        case .videoInterruptedByScreenshot(_, let item, _):
            CopiedToastView(copyID: item.id)
                .id(item.id)

        case .recording(let duration, let isPaused):
            ClipNotchRecordingView(
                durationSeconds: duration,
                isPaused: isPaused,
                onPauseResume: {
                    if isPaused {
                        ScreenRecordingEngine.shared.resumeRecording()
                    } else {
                        ScreenRecordingEngine.shared.pauseRecording()
                    }
                },
                onStop: {
                    ScreenRecordingEngine.shared.stopRecording(save: true)
                    viewModel.showIdle()
                }
            )

        case .ocrResult(let text):
            ClipNotchOCRView(
                text: text,
                onOpenFullText: {
                    OCRResultWindowController.show(text: text)
                },
                onClose: {
                    viewModel.showIdle()
                }
            )

        case .colorResult(let hex, let rgb, let hsl):
            ClipNotchColorView(
                hex: hex,
                rgb: rgb,
                hsl: hsl,
                onClose: {
                    viewModel.showIdle()
                }
            )

        case .error(let message):
            ClipNotchErrorRailView(
                message: message,
                onDismiss: { viewModel.showIdle() }
            )

        case .fileDropHover:
            ClipNotchFileDropTargetView()

        case .recentShelf(let items):
            ClipNotchRecentShelfView(
                items: items,
                onSelect: { item in
                    if let url = item.effectiveImageURL, let img = ImageUtils.loadImage(at: url) {
                        ClipboardManager.shared.copy(image: img, fileURL: url)
                        viewModel.showScreenshot(item: item, image: img)
                    }
                },
                onOpenHistory: {
                    HistoryWindowController.shared.showHistory()
                },
                onClose: {
                    viewModel.showIdle()
                }
            )
            .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
        }
    }

    private var stateAccent: (color: Color, opacity: Double) {
        switch viewModel.currentState {
        case .idle:
            return (settings.clipNotchColorway.primaryAccent, 0.07)
        case .quickActions:
            return (Color.cyan, 0.06)
        case .musicPlayer:
            return (settings.clipNotchColorway.primaryAccent, 0.12)
        case .screenshotPreview, .videoInterruptedByScreenshot:
            return (Color.green, 0.08)
        case .video:
            return (Color.blue, 0.06)
        case .recording(_, let isPaused):
            return isPaused ? (Color.orange, 0.07) : (Color.red, 0.09)
        case .ocrResult:
            return (Color.purple, 0.08)
        case .colorResult(let hex, _, _):
            return (Color(hex: hex), 0.10)
        case .error:
            return (Color.orange, 0.08)
        case .fileDropHover:
            return (Color.cyan, 0.10)
        case .recentShelf:
            return (Color.mint, 0.06)
        }
    }

    private var backgroundAnimationKey: String {
        if case .recording(_, let isPaused) = viewModel.currentState {
            return "recording-\(isPaused)"
        }
        return viewModel.currentState.presentationKind.rawValue
    }

    @ViewBuilder
    private var notchBackground: some View {
        let accent = stateAccent
        let finish = settings.clipNotchFinish
        let washMultiplier = finish.radialWashMultiplier
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
                    accent.color.opacity(accent.opacity * washMultiplier),
                    accent.color.opacity(accent.opacity * 0.35 * washMultiplier),
                    Color.clear
                ]),
                center: UnitPoint(x: 0.5, y: 1.0),
                startRadius: 0,
                endRadius: 90
            )
            .animation(
                reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.88),
                value: backgroundAnimationKey
            )
        }
    }

    private var notchClipShape: some Shape {
        if settings.clipNotchPlacementMode != .floatingIsland {
            return AnyShape(AppleNotchShape(
                bottomCornerRadius: settings.clipNotchSize.bottomCornerRadius,
                topWingRadius: settings.clipNotchSize.topWingRadius
            ))
        } else {
            return AnyShape(RoundedRectangle(cornerRadius: settings.clipNotchSize.bottomCornerRadius + 3, style: .continuous))
        }
    }

    private func handleHover(_ hovering: Bool) {
        hoverWorkItem?.cancel()

        let item = DispatchWorkItem { [weak viewModel] in
            if !hovering, ClipNotchController.shared.containsMouse() {
                return
            }
            viewModel?.setHovered(hovering)
        }
        hoverWorkItem = item
        // Resizing an NSPanel briefly invalidates its tracking area. A delayed exit
        // lets the matching re-entry cancel that false event instead of oscillating.
        let delay = hovering ? 0.1 : 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    @ViewBuilder
    private var notchContextMenu: some View {
        Button("Capture Area") { CaptureOverlayController.shared.showOverlay(initialMode: .area) }
        Button("Capture Window") { CaptureOverlayController.shared.showOverlay(initialMode: .window) }
        Button("Capture Full Screen") { CaptureOverlayController.shared.showOverlay(initialMode: .screen) }

        Divider()

        Button("OCR Area") { CaptureOverlayController.shared.showOverlay(initialMode: .ocr) }
        Button("Color Picker") { CaptureOverlayController.shared.showOverlay(initialMode: .colorPicker) }
        Button("Record Screen") { CaptureOverlayController.shared.showOverlay(initialMode: .record) }

        Divider()

        Menu("Move ClipNotch to Display") {
            ForEach(displayTracker.availableDisplays) { display in
                Button(display.displayName) {
                    settings.clipNotchDisplayUUID = display.id
                }
            }
        }

        Divider()

        Button("Screenshot History...") { HistoryWindowController.shared.showHistory() }
        Button("ClipShot Settings...") { SettingsWindowController.shared.showSettings() }
        Button("Hide ClipNotch") { settings.clipNotchEnabled = false }
    }

    // MARK: - Actions

    private func togglePopOutMiniPlayer(model: VideoCapsuleModel) {
        VideoCapsulePopOutController.shared.show(model: model)
    }
}

private struct CopiedToastView: View {
    let copyID: UUID

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(.black)
                .frame(width: 17, height: 17)
                .background(Circle().fill(.green))
                .scaleEffect(revealed ? 1 : 0.65)

            Text("Copied")
                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .offset(x: revealed ? 0 : -3)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Capsule().fill(.green.opacity(0.07)))
        .overlay {
            Capsule()
                .stroke(.green.opacity(revealed ? 0.16 : 0.65), lineWidth: 0.8)
                .scaleEffect(revealed ? 1 : 0.82)
        }
        .opacity(revealed ? 1 : 0)
        .onAppear {
            if reduceMotion {
                revealed = true
            } else {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.74)) {
                    revealed = true
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Screenshot copied")
    }
}

private struct ClipNotchErrorRailView: View {
    let message: String
    let onDismiss: () -> Void

    @State private var isDismissHovered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.orange)

            Text(message)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer(minLength: 4)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundStyle(.white.opacity(isDismissHovered ? 0.95 : 0.6))
                    .frame(width: 18, height: 18)
                    .background(Circle().fill(Color.white.opacity(isDismissHovered ? 0.14 : 0.06)))
            }
            .buttonStyle(.plain)
            .help("Dismiss")
            .accessibilityLabel("Dismiss error")
            .onHover { isDismissHovered = $0 }
        }
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(
            Capsule(style: .continuous)
                .fill(Color.orange.opacity(0.08))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.orange.opacity(0.22), lineWidth: 0.6)
        )
        .padding(.horizontal, 6)
        .frame(height: 38)
        .transition(.opacity)
        .accessibilityElement(children: .contain)
    }
}

private struct ClipNotchFileDropTargetView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isRevealed = false

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.15))
                    .frame(width: 22, height: 22)

                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.cyan)
            }
            .scaleEffect(isRevealed ? 1.0 : 0.8)

            Text("Drop to Pin")
                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.cyan.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.cyan.opacity(0.24), lineWidth: 0.75)
        )
        .padding(4)
        .opacity(isRevealed ? 1 : 0)
        .onAppear {
            if reduceMotion {
                isRevealed = true
            } else {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                    isRevealed = true
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Drop file to pin to recent shelf")
    }
}

/// Hardware notch shape matching Apple's silhouette:
/// Flat top flush with monitor bezel, smooth concave outward wings, and smooth bottom continuous curves.
public struct AppleNotchShape: Shape {
    var bottomCornerRadius: CGFloat = 18
    var topWingRadius: CGFloat = 12

    public func path(in rect: CGRect) -> Path {
        var path = Path()

        let effectiveBottomRadius = max(0, min(bottomCornerRadius, rect.height, rect.width / 2))
        let effectiveWingRadius = max(0, min(topWingRadius, (rect.width - 2 * effectiveBottomRadius) / 2, rect.height - effectiveBottomRadius))

        // Start at top-left wing point flush with display bezel
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))

        // Top edge flush with display boundary
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        if effectiveWingRadius > 0 {
            // Top-right concave outward wing curving down into notch body
            path.addArc(
                center: CGPoint(x: rect.maxX, y: rect.minY + effectiveWingRadius),
                radius: effectiveWingRadius,
                startAngle: .degrees(270),
                endAngle: .degrees(180),
                clockwise: true
            )
        }

        // Right vertical side down to bottom-right curve
        let rightX = rect.maxX - effectiveWingRadius
        path.addLine(to: CGPoint(x: rightX, y: rect.maxY - effectiveBottomRadius))

        if effectiveBottomRadius > 0 {
            // Bottom-right smooth arc
            path.addArc(
                center: CGPoint(x: rightX - effectiveBottomRadius, y: rect.maxY - effectiveBottomRadius),
                radius: effectiveBottomRadius,
                startAngle: .degrees(0),
                endAngle: .degrees(90),
                clockwise: false
            )
        }

        // Bottom edge
        let leftX = rect.minX + effectiveWingRadius
        path.addLine(to: CGPoint(x: leftX + effectiveBottomRadius, y: rect.maxY))

        if effectiveBottomRadius > 0 {
            // Bottom-left smooth arc
            path.addArc(
                center: CGPoint(x: leftX + effectiveBottomRadius, y: rect.maxY - effectiveBottomRadius),
                radius: effectiveBottomRadius,
                startAngle: .degrees(90),
                endAngle: .degrees(180),
                clockwise: false
            )
        }

        // Left vertical side up to top-left wing
        path.addLine(to: CGPoint(x: leftX, y: rect.minY + effectiveWingRadius))

        if effectiveWingRadius > 0 {
            // Top-left concave outward wing curving up flush with display bezel
            path.addArc(
                center: CGPoint(x: rect.minX, y: rect.minY + effectiveWingRadius),
                radius: effectiveWingRadius,
                startAngle: .degrees(0),
                endAngle: .degrees(-90),
                clockwise: true
            )
        }

        path.closeSubpath()
        return path
    }
}

/// Type-erased Shape wrapper for SwiftUI compatibility
public struct AnyShape: Shape {
    private let pathClosure: @Sendable (CGRect) -> Path

    public init<S: Shape>(_ shape: S) {
        self.pathClosure = { rect in
            shape.path(in: rect)
        }
    }

    public func path(in rect: CGRect) -> Path {
        pathClosure(rect)
    }
}
