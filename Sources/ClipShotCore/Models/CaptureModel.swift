import Foundation
import CoreGraphics
import AppKit

/// Active capture mode within the full-screen capture overlay.
public enum CaptureMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case area = "area"
    case window = "window"
    case screen = "screen"
    case scrolling = "scrolling"
    case ocr = "ocr"
    case record = "record"
    case colorPicker = "color_picker"
    case measure = "measure"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .area: return "Area"
        case .window: return "Window"
        case .screen: return "Screen"
        case .scrolling: return "Scroll"
        case .ocr: return "OCR"
        case .record: return "Record"
        case .colorPicker: return "Color"
        case .measure: return "Measure"
        }
    }

    public var iconName: String {
        switch self {
        case .area: return "crop"
        case .window: return "rectangle.inset.filled"
        case .screen: return "macwindow"
        case .scrolling: return "arrow.down.doc"
        case .ocr: return "text.viewfinder"
        case .record: return "record.circle"
        case .colorPicker: return "eyedropper"
        case .measure: return "ruler"
        }
    }
}

/// Color format for the color picker tool.
public enum ColorFormat: String, CaseIterable, Identifiable, Codable, Sendable {
    case hex = "HEX"
    case rgb = "RGB"
    case hsl = "HSL"
    case displayP3 = "Display P3"

    public var id: String { rawValue }
}

/// Drag handle positions for 8-handle region resizing.
public enum ResizeHandle: CaseIterable, Sendable {
    case topLeft
    case top
    case topRight
    case left
    case right
    case bottomLeft
    case bottom
    case bottomRight

    public var cursor: NSCursor {
        switch self {
        case .topLeft, .bottomRight: return .arrow // or diagonal resize cursor
        case .topRight, .bottomLeft: return .arrow
        case .top, .bottom: return .resizeUpDown
        case .left, .right: return .resizeLeftRight
        }
    }
}

/// Floating dock launcher style.
public enum FloatingToolStyle: String, CaseIterable, Identifiable, Codable, Sendable {
    case button = "button"
    case expanded = "expanded"
    case hidden = "hidden"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .button: return "Compact Button"
        case .expanded: return "Expanded Dock"
        case .hidden: return "Hidden"
        }
    }
}

/// Information about a detected macOS on-screen window.
public struct WindowInfo: Identifiable, Sendable, Equatable {
    public let id: CGWindowID
    public let windowName: String
    public let ownerName: String
    public let bounds: CGRect
    public let windowLayer: Int

    public init(id: CGWindowID, windowName: String, ownerName: String, bounds: CGRect, windowLayer: Int) {
        self.id = id
        self.windowName = windowName
        self.ownerName = ownerName
        self.bounds = bounds
        self.windowLayer = windowLayer
    }

    public var displayName: String {
        if !windowName.isEmpty && !ownerName.isEmpty {
            return "\(ownerName) — \(windowName)"
        }
        return ownerName.isEmpty ? "Window #\(id)" : ownerName
    }
}
