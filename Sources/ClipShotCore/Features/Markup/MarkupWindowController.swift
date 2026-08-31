import Foundation
import AppKit
import SwiftUI

/// Annotation element types for the markup canvas.
public enum MarkupTool: String, CaseIterable, Identifiable {
    case arrow = "Arrow"
    case line = "Line"
    case rectangle = "Rectangle"
    case ellipse = "Ellipse"
    case step = "Step"
    case pen = "Pen"
    case text = "Text"
    case highlight = "Highlight"
    case blur = "Blur"
    case pixelate = "Pixelate"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .arrow: return "arrow.up.right"
        case .line: return "line.diagonal"
        case .rectangle: return "rectangle"
        case .ellipse: return "circle"
        case .step: return "number.circle.fill"
        case .pen: return "pencil.tip"
        case .text: return "textformat"
        case .highlight: return "highlighter"
        case .blur: return "checkerboard.rectangle"
        case .pixelate: return "square.grid.3x3.fill"
        }
    }
}

/// An individual drawing element on the markup canvas.
public struct MarkupElement: Identifiable {
    public let id = UUID()
    public var tool: MarkupTool
    public var startPoint: CGPoint
    public var endPoint: CGPoint
    public var points: [CGPoint] = []
    public var color: Color
    public var strokeWidth: CGFloat
    public var text: String = ""
}

public final class MarkupWindowController: NSWindowController {
    public static var activeControllers: [MarkupWindowController] = []

    public static func open(image: NSImage, sourceURL: URL? = nil) {
        let controller = MarkupWindowController(image: image, sourceURL: sourceURL)
        activeControllers.append(controller)
        controller.showWindow(nil)
        controller.window?.center()
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private let image: NSImage
    private let sourceURL: URL?

    init(image: NSImage, sourceURL: URL?) {
        self.image = image
        self.sourceURL = sourceURL

        let screen = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1200, height: 800)
        let maxW = min(max(image.size.width + 100, 700), screen.width - 100)
        let maxH = min(max(image.size.height + 140, 500), screen.height - 100)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: maxW, height: maxH),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "\(AppConfig.appName) — Markup & Annotation"
        window.isReleasedWhenClosed = false

        super.init(window: window)

        let contentView = MarkupView(
            originalImage: image,
            sourceURL: sourceURL,
            onClose: { [weak self] in self?.closeWindow() }
        )
        window.contentViewController = NSHostingController(rootView: contentView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func closeWindow() {
        window?.close()
        MarkupWindowController.activeControllers.removeAll { $0 === self }
    }
}

public struct MarkupView: View {
    let originalImage: NSImage
    let sourceURL: URL?
    let onClose: () -> Void

    @State private var selectedTool: MarkupTool = .arrow
    @State private var selectedColor: Color = .red
    @State private var strokeWidth: CGFloat = 4.0
    @State private var elements: [MarkupElement] = []
    @State private var redoStack: [MarkupElement] = []
    @State private var currentDrawing: MarkupElement?
    @State private var textInput: String = "Note"

    private let palette: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .black, .white]

    public var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                // Tools picker
                ForEach(MarkupTool.allCases) { tool in
                    Button(action: { selectedTool = tool }) {
                        Image(systemName: tool.iconName)
                            .font(.system(size: 14))
                            .frame(width: 28, height: 28)
                            .background(selectedTool == tool ? Color.accentColor.opacity(0.25) : Color.clear)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help(tool.rawValue)
                }

                Divider().frame(height: 20)

                // Color palette
                ForEach(palette, id: \.self) { col in
                    Button(action: { selectedColor = col }) {
                        Circle()
                            .fill(col)
                            .frame(width: 18, height: 18)
                            .overlay(
                                Circle()
                                    .stroke(selectedColor == col ? Color.primary : Color.secondary.opacity(0.3), lineWidth: selectedColor == col ? 2 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Divider().frame(height: 20)

                // Stroke width
                Menu {
                    Button("Thin (2px)") { strokeWidth = 2.0 }
                    Button("Medium (4px)") { strokeWidth = 4.0 }
                    Button("Thick (8px)") { strokeWidth = 8.0 }
                } label: {
                    HStack {
                        Image(systemName: "line.horizontal.3")
                        Text("\(Int(strokeWidth))px")
                    }
                }
                .menuStyle(.borderlessButton)
                .frame(width: 80)

                Spacer()

                // Undo / Redo
                Button(action: undo) {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(elements.isEmpty)
                .help("Undo (⌘Z)")

                Button(action: redo) {
                    Image(systemName: "arrow.uturn.forward")
                }
                .disabled(redoStack.isEmpty)
                .help("Redo (⇧⌘Z)")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Canvas Area
            GeometryReader { geometry in
                ZStack {
                    Color(NSColor.underPageBackgroundColor)

                    Image(nsImage: originalImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: geometry.size.width - 20, maxHeight: geometry.size.height - 20)
                        .overlay(
                            CanvasOverlay(
                                elements: elements,
                                currentDrawing: currentDrawing,
                                selectedTool: selectedTool,
                                selectedColor: selectedColor,
                                strokeWidth: strokeWidth,
                                onDrawingEnded: { newElement in
                                    elements.append(newElement)
                                    redoStack.removeAll()
                                    currentDrawing = nil
                                },
                                onDrawingChanged: { updated in
                                    currentDrawing = updated
                                }
                            )
                        )
                }
            }

            Divider()

            // Bottom Action Bar
            HStack {
                Button("Cancel") {
                    onClose()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save As...") {
                    saveAs()
                }

                if let url = sourceURL {
                    Button("Save") {
                        saveOverwrite(to: url)
                    }
                }

                Button("Copy Annotated Image") {
                    copyRendered()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(12)
            .background(Color(NSColor.windowBackgroundColor))
        }
    }

    private func undo() {
        if let last = elements.popLast() {
            redoStack.append(last)
        }
    }

    private func redo() {
        if let last = redoStack.popLast() {
            elements.append(last)
        }
    }

    private func renderAnnotatedImage() -> NSImage {
        let size = originalImage.size
        let image = NSImage(size: size)

        image.lockFocus()
        originalImage.draw(in: NSRect(origin: .zero, size: size))

        let nsContext = NSGraphicsContext.current?.cgContext
        if let ctx = nsContext {
            for element in elements {
                drawElement(element, in: ctx, canvasSize: size)
            }
        }

        image.unlockFocus()
        return image
    }

    private func drawElement(_ element: MarkupElement, in ctx: CGContext, canvasSize: CGSize) {
        ctx.saveGState()

        let nsColor = NSColor(element.color)
        ctx.setStrokeColor(nsColor.cgColor)
        ctx.setFillColor(nsColor.cgColor)
        ctx.setLineWidth(element.strokeWidth)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)

        switch element.tool {
        case .arrow:
            drawArrow(from: element.startPoint, to: element.endPoint, in: ctx, width: element.strokeWidth)
        case .line:
            ctx.beginPath()
            ctx.move(to: element.startPoint)
            ctx.addLine(to: element.endPoint)
            ctx.strokePath()
        case .step:
            let radius: CGFloat = max(element.strokeWidth * 3.5, 14.0)
            let circleRect = CGRect(x: element.startPoint.x - radius, y: element.startPoint.y - radius, width: radius * 2, height: radius * 2)
            ctx.setFillColor(nsColor.cgColor)
            ctx.fillEllipse(in: circleRect)

            let numStr = NSString(string: element.text.isEmpty ? "1" : element.text)
            let textAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: radius * 1.1),
                .foregroundColor: NSColor.white
            ]
            let textSize = numStr.size(withAttributes: textAttrs)
            let textPoint = CGPoint(
                x: element.startPoint.x - textSize.width / 2,
                y: element.startPoint.y - textSize.height / 2
            )
            numStr.draw(at: textPoint, withAttributes: textAttrs)
        case .rectangle:
            let rect = CGRect(
                x: min(element.startPoint.x, element.endPoint.x),
                y: min(element.startPoint.y, element.endPoint.y),
                width: abs(element.endPoint.x - element.startPoint.x),
                height: abs(element.endPoint.y - element.startPoint.y)
            )
            ctx.stroke(rect)
        case .ellipse:
            let rect = CGRect(
                x: min(element.startPoint.x, element.endPoint.x),
                y: min(element.startPoint.y, element.endPoint.y),
                width: abs(element.endPoint.x - element.startPoint.x),
                height: abs(element.endPoint.y - element.startPoint.y)
            )
            ctx.strokeEllipse(in: rect)
        case .pen:
            guard let first = element.points.first else { break }
            ctx.beginPath()
            ctx.move(to: first)
            for p in element.points.dropFirst() {
                ctx.addLine(to: p)
            }
            ctx.strokePath()
        case .highlight:
            ctx.setAlpha(0.35)
            let rect = CGRect(
                x: min(element.startPoint.x, element.endPoint.x),
                y: min(element.startPoint.y, element.endPoint.y),
                width: abs(element.endPoint.x - element.startPoint.x),
                height: abs(element.endPoint.y - element.startPoint.y)
            )
            ctx.fill(rect)
        case .blur, .pixelate:
            let rect = CGRect(
                x: min(element.startPoint.x, element.endPoint.x),
                y: min(element.startPoint.y, element.endPoint.y),
                width: abs(element.endPoint.x - element.startPoint.x),
                height: abs(element.endPoint.y - element.startPoint.y)
            )
            ctx.setLineDash(phase: 0, lengths: [4, 4])
            ctx.stroke(rect)
        case .text:
            let str = NSString(string: element.text.isEmpty ? "Annotation" : element.text)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: element.strokeWidth * 4),
                .foregroundColor: nsColor
            ]
            str.draw(at: element.startPoint, withAttributes: attrs)
        }

        ctx.restoreGState()
    }

    private func drawArrow(from start: CGPoint, to end: CGPoint, in ctx: CGContext, width: CGFloat) {
        ctx.beginPath()
        ctx.move(to: start)
        ctx.addLine(to: end)
        ctx.strokePath()

        // Arrow head
        let angle = atan2(end.y - start.y, end.x - start.x)
        let arrowLength: CGFloat = max(width * 3.5, 14.0)
        let arrowAngle: CGFloat = .pi / 6

        let p1 = CGPoint(
            x: end.x - arrowLength * cos(angle - arrowAngle),
            y: end.y - arrowLength * sin(angle - arrowAngle)
        )
        let p2 = CGPoint(
            x: end.x - arrowLength * cos(angle + arrowAngle),
            y: end.y - arrowLength * sin(angle + arrowAngle)
        )

        ctx.beginPath()
        ctx.move(to: end)
        ctx.addLine(to: p1)
        ctx.addLine(to: p2)
        ctx.closePath()
        ctx.fillPath()
    }

    private func copyRendered() {
        let image = renderAnnotatedImage()
        ClipboardManager.shared.copy(image: image)
        SoundManager.shared.playCopySound()
        onClose()
    }

    private func saveOverwrite(to url: URL) {
        let image = renderAnnotatedImage()
        try? ImageUtils.savePNG(image: image, to: url)
        ClipboardManager.shared.copy(image: image)
        onClose()
    }

    private func saveAs() {
        let image = renderAnnotatedImage()
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = "Annotated Screenshot.png"

        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                try? ImageUtils.savePNG(image: image, to: url)
                self.onClose()
            }
        }
    }
}

public struct CanvasOverlay: View {
    let elements: [MarkupElement]
    let currentDrawing: MarkupElement?
    let selectedTool: MarkupTool
    let selectedColor: Color
    let strokeWidth: CGFloat
    let onDrawingEnded: (MarkupElement) -> Void
    let onDrawingChanged: (MarkupElement) -> Void

    @State private var dragStart: CGPoint?
    @State private var currentPoints: [CGPoint] = []

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Render completed elements
                ForEach(elements) { el in
                    renderShape(el, in: proxy.size)
                }

                // Render active in-progress drawing
                if let active = currentDrawing {
                    renderShape(active, in: proxy.size)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if dragStart == nil {
                            dragStart = value.startLocation
                            currentPoints = [value.startLocation]
                        }
                        currentPoints.append(value.location)

                        let element = MarkupElement(
                            tool: selectedTool,
                            startPoint: dragStart ?? value.startLocation,
                            endPoint: value.location,
                            points: currentPoints,
                            color: selectedColor,
                            strokeWidth: strokeWidth
                        )
                        onDrawingChanged(element)
                    }
                    .onEnded { value in
                        if let start = dragStart {
                            let element = MarkupElement(
                                tool: selectedTool,
                                startPoint: start,
                                endPoint: value.location,
                                points: currentPoints,
                                color: selectedColor,
                                strokeWidth: strokeWidth
                            )
                            onDrawingEnded(element)
                        }
                        dragStart = nil
                        currentPoints = []
                    }
            )
        }
    }

    @ViewBuilder
    private func renderShape(_ element: MarkupElement, in size: CGSize) -> some View {
        switch element.tool {
        case .arrow:
            Path { path in
                path.move(to: element.startPoint)
                path.addLine(to: element.endPoint)
            }
            .stroke(element.color, style: StrokeStyle(lineWidth: element.strokeWidth, lineCap: .round, lineJoin: .round))

        case .line:
            Path { path in
                path.move(to: element.startPoint)
                path.addLine(to: element.endPoint)
            }
            .stroke(element.color, style: StrokeStyle(lineWidth: element.strokeWidth, lineCap: .round, lineJoin: .round))

        case .step:
            let radius: CGFloat = max(element.strokeWidth * 3.5, 14.0)
            ZStack {
                Circle()
                    .fill(element.color)
                    .frame(width: radius * 2, height: radius * 2)
                Text(element.text.isEmpty ? "1" : element.text)
                    .font(.system(size: radius * 1.1, weight: .bold))
                    .foregroundColor(.white)
            }
            .position(element.startPoint)

        case .rectangle:
            let rect = CGRect(
                x: min(element.startPoint.x, element.endPoint.x),
                y: min(element.startPoint.y, element.endPoint.y),
                width: abs(element.endPoint.x - element.startPoint.x),
                height: abs(element.endPoint.y - element.startPoint.y)
            )
            Path { path in
                path.addRect(rect)
            }
            .stroke(element.color, lineWidth: element.strokeWidth)

        case .ellipse:
            let rect = CGRect(
                x: min(element.startPoint.x, element.endPoint.x),
                y: min(element.startPoint.y, element.endPoint.y),
                width: abs(element.endPoint.x - element.startPoint.x),
                height: abs(element.endPoint.y - element.startPoint.y)
            )
            Path { path in
                path.addEllipse(in: rect)
            }
            .stroke(element.color, lineWidth: element.strokeWidth)

        case .pen:
            Path { path in
                if let first = element.points.first {
                    path.move(to: first)
                    for p in element.points.dropFirst() {
                        path.addLine(to: p)
                    }
                }
            }
            .stroke(element.color, style: StrokeStyle(lineWidth: element.strokeWidth, lineCap: .round, lineJoin: .round))

        case .highlight:
            let rect = CGRect(
                x: min(element.startPoint.x, element.endPoint.x),
                y: min(element.startPoint.y, element.endPoint.y),
                width: abs(element.endPoint.x - element.startPoint.x),
                height: abs(element.endPoint.y - element.startPoint.y)
            )
            Path { path in
                path.addRect(rect)
            }
            .fill(element.color.opacity(0.35))

        case .blur, .pixelate:
            let rect = CGRect(
                x: min(element.startPoint.x, element.endPoint.x),
                y: min(element.startPoint.y, element.endPoint.y),
                width: abs(element.endPoint.x - element.startPoint.x),
                height: abs(element.endPoint.y - element.startPoint.y)
            )
            Path { path in
                path.addRect(rect)
            }
            .stroke(element.color, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))

        case .text:
            Text(element.text.isEmpty ? "Annotation" : element.text)
                .font(.system(size: element.strokeWidth * 4, weight: .bold))
                .foregroundColor(element.color)
                .position(element.startPoint)
        }
    }
}
