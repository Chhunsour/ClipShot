import Foundation
import AppKit
import SwiftUI

/// Full-screen interactive overlay view handling selection geometry, window highlights, loupe, and measurement.
public struct CaptureOverlayView: View {
    @Binding var selectedMode: CaptureMode
    let screenBounds: CGRect
    let onCaptureRect: (CGRect) -> Void
    let onCaptureWindow: (WindowInfo) -> Void
    let onCaptureScreen: () -> Void
    let onColorSampled: (CGPoint) -> Void
    let onCancel: () -> Void
    let onOpenSettings: () -> Void

    @State private var dragStart: CGPoint?
    @State private var currentPoint: CGPoint = .zero
    @State private var selectionRect: CGRect?
    @State private var activeHandle: ResizeHandle?
    @State private var hoveredWindow: WindowInfo?
    @State private var magnifiedCG: CGImage?
    @State private var targetColor: NSColor?
    @State private var isMovingSelection: Bool = false
    @State private var moveOffset: CGPoint = .zero

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Dimmed background with cutout for active selection
                Canvas { context, size in
                    let fullRect = CGRect(origin: .zero, size: size)
                    context.fill(Path(fullRect), with: .color(Color.black.opacity(0.35)))

                    if let sel = effectiveSelectionRect {
                        context.blendMode = .clear
                        context.fill(Path(sel), with: .color(.black))
                    } else if selectedMode == .window, let win = hoveredWindow {
                        context.blendMode = .clear
                        context.fill(Path(win.bounds), with: .color(.black))
                    }
                }

                // Active selection border and 8 handles
                if let sel = effectiveSelectionRect {
                    SelectionOverlay(
                        rect: sel,
                        showDimensions: AppSettings.shared.showDimensions,
                        mode: selectedMode
                    )
                }

                // Window highlight border
                if selectedMode == .window, let win = hoveredWindow {
                    WindowHighlightOverlay(window: win)
                }

                // Precision Loupe (in area, colorPicker, and measure modes)
                if shouldShowLoupe && currentPoint != .zero {
                    PrecisionLoupeView(
                        magnifiedImage: magnifiedCG,
                        targetColor: targetColor,
                        point: currentPoint
                    )
                    .position(loupePosition(for: currentPoint, in: proxy.size))
                }

                // Floating Toolbar
                VStack {
                    Spacer()
                    CaptureToolbarView(
                        selectedMode: $selectedMode,
                        onCaptureTriggered: triggerCurrentCapture,
                        onCancel: onCancel,
                        onOpenSettings: onOpenSettings
                    )
                    .padding(.bottom, 32)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDragChanged(value: value)
                    }
                    .onEnded { value in
                        handleDragEnded(value: value)
                    }
            )
            .onAppear {
                NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .keyDown]) { event in
                    if event.type == .mouseMoved {
                        handleMouseMove(event: event)
                    } else if event.type == .keyDown {
                        handleKeyDown(event: event)
                    }
                    return event
                }
            }
        }
    }

    private var effectiveSelectionRect: CGRect? {
        if let sel = selectionRect { return sel }
        if let start = dragStart {
            return CGRect(
                x: min(start.x, currentPoint.x),
                y: min(start.y, currentPoint.y),
                width: abs(currentPoint.x - start.x),
                height: abs(currentPoint.y - start.y)
            )
        }
        return nil
    }

    private var shouldShowLoupe: Bool {
        if selectedMode == .colorPicker { return true }
        if (selectedMode == .area || selectedMode == .ocr || selectedMode == .measure) && AppSettings.shared.showMagnifier {
            return selectionRect == nil
        }
        return false
    }

    private func loupePosition(for point: CGPoint, in size: CGSize) -> CGPoint {
        let offsetX: CGFloat = point.x + 80 > size.width ? -80 : 80
        let offsetY: CGFloat = point.y - 80 < 0 ? 80 : -80
        return CGPoint(x: point.x + offsetX, y: point.y + offsetY)
    }

    // MARK: - Event Handling

    private func handleMouseMove(event: NSEvent) {
        let loc = event.locationInWindow
        currentPoint = CGPoint(x: loc.x, y: screenBounds.height - loc.y)

        if selectedMode == .window {
            hoveredWindow = WindowCaptureService.shared.window(at: currentPoint)
        } else if shouldShowLoupe {
            magnifiedCG = ScreenCaptureEngine.shared.captureMagnifierRegion(at: currentPoint)
            targetColor = ScreenCaptureEngine.shared.sampleColor(at: currentPoint)
        }
    }

    private func handleKeyDown(event: NSEvent) {
        if event.keyCode == 53 { // Esc
            onCancel()
        } else if event.keyCode == 36 { // Enter
            triggerCurrentCapture()
        } else if event.keyCode == 123 { // Left arrow
            nudgeSelection(dx: event.modifierFlags.contains(.shift) ? -10 : -1, dy: 0)
        } else if event.keyCode == 124 { // Right arrow
            nudgeSelection(dx: event.modifierFlags.contains(.shift) ? 10 : 1, dy: 0)
        } else if event.keyCode == 125 { // Down arrow
            nudgeSelection(dx: 0, dy: event.modifierFlags.contains(.shift) ? 10 : 1)
        } else if event.keyCode == 126 { // Up arrow
            nudgeSelection(dx: 0, dy: event.modifierFlags.contains(.shift) ? -10 : -1)
        }
    }

    private func nudgeSelection(dx: CGFloat, dy: CGFloat) {
        guard var sel = selectionRect else { return }
        sel.origin.x += dx
        sel.origin.y += dy
        selectionRect = sel
    }

    private func handleDragChanged(value: DragGesture.Value) {
        let loc = value.location
        currentPoint = loc

        if selectedMode == .colorPicker {
            return
        }

        if dragStart == nil {
            dragStart = value.startLocation
        }
    }

    private func handleDragEnded(value: DragGesture.Value) {
        if selectedMode == .colorPicker {
            onColorSampled(currentPoint)
            return
        }

        if selectedMode == .window, let win = hoveredWindow {
            onCaptureWindow(win)
            return
        }

        if selectedMode == .screen {
            onCaptureScreen()
            return
        }

        if let start = dragStart {
            let rect = CGRect(
                x: min(start.x, value.location.x),
                y: min(start.y, value.location.y),
                width: abs(value.location.x - start.x),
                height: abs(value.location.y - start.y)
            )

            if rect.width > 10 && rect.height > 10 {
                selectionRect = rect
                onCaptureRect(rect)
            }
        }
        dragStart = nil
    }

    private func triggerCurrentCapture() {
        if let sel = selectionRect {
            onCaptureRect(sel)
        } else if selectedMode == .window, let win = hoveredWindow {
            onCaptureWindow(win)
        } else if selectedMode == .screen {
            onCaptureScreen()
        }
    }
}

struct SelectionOverlay: View {
    let rect: CGRect
    let showDimensions: Bool
    let mode: CaptureMode

    var body: some View {
        ZStack {
            // Crisp border
            Rectangle()
                .path(in: rect)
                .stroke(Color.accentColor, lineWidth: 2)

            // 8 Resize Handles
            ForEach(ResizeHandle.allCases, id: \.self) { handle in
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(Color.accentColor, lineWidth: 1.5))
                    .position(handlePosition(for: handle, in: rect))
            }

            // Dimensions badge
            if showDimensions {
                Text("\(Int(rect.width)) × \(Int(rect.height)) px")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(4)
                    .position(x: rect.midX, y: rect.maxY + 18)
            }
        }
    }

    private func handlePosition(for handle: ResizeHandle, in r: CGRect) -> CGPoint {
        switch handle {
        case .topLeft: return CGPoint(x: r.minX, y: r.minY)
        case .top: return CGPoint(x: r.midX, y: r.minY)
        case .topRight: return CGPoint(x: r.maxX, y: r.minY)
        case .left: return CGPoint(x: r.minX, y: r.midY)
        case .right: return CGPoint(x: r.maxX, y: r.midY)
        case .bottomLeft: return CGPoint(x: r.minX, y: r.maxY)
        case .bottom: return CGPoint(x: r.midX, y: r.maxY)
        case .bottomRight: return CGPoint(x: r.maxX, y: r.maxY)
        }
    }
}

struct WindowHighlightOverlay: View {
    let window: WindowInfo

    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .path(in: window.bounds)
                .stroke(Color.accentColor, lineWidth: 2.5)

            Text(window.displayName)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.accentColor)
                .cornerRadius(4)
                .position(x: window.bounds.minX + 60, y: max(window.bounds.minY - 14, 20))
        }
    }
}
