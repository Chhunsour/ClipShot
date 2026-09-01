import Foundation
import AppKit

/// Explicit state machine modeling ClipNotch visual mode and content.
public enum ClipNotchState: Equatable, Sendable {
    case idle
    case quickActions
    case musicPlayer
    case screenshotPreview(item: ScreenshotItem, image: NSImage)
    case video(model: VideoCapsuleModel)
    case videoInterruptedByScreenshot(video: VideoCapsuleModel, screenshot: ScreenshotItem, image: NSImage)
    case recording(durationSeconds: Int, isPaused: Bool)
    case ocrResult(text: String)
    case colorResult(hex: String, rgb: String, hsl: String)
    case error(message: String)
    case fileDropHover
    case recentShelf(items: [ScreenshotItem])

    public enum PresentationKind: String, Equatable, Hashable, Sendable {
        case idle
        case quickActions
        case musicPlayer
        case screenshotPreview
        case video
        case recording
        case ocrResult
        case colorResult
        case error
        case fileDropHover
        case recentShelf
    }

    public var presentationKind: PresentationKind {
        switch self {
        case .idle:
            return .idle
        case .quickActions:
            return .quickActions
        case .musicPlayer:
            return .musicPlayer
        case .screenshotPreview, .videoInterruptedByScreenshot:
            return .screenshotPreview
        case .video:
            return .video
        case .recording:
            return .recording
        case .ocrResult:
            return .ocrResult
        case .colorResult:
            return .colorResult
        case .error:
            return .error
        case .fileDropHover:
            return .fileDropHover
        case .recentShelf:
            return .recentShelf
        }
    }

    public var isVideoActive: Bool {
        switch self {
        case .video, .videoInterruptedByScreenshot:
            return true
        default:
            return false
        }
    }

    public var activeVideoModel: VideoCapsuleModel? {
        switch self {
        case .video(let model):
            return model
        case .videoInterruptedByScreenshot(let video, _, _):
            return video
        default:
            return nil
        }
    }
}

/// Placement / Positioning mode for ClipNotch.
public enum ClipNotchPlacementMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case topHeader = "Top Header / Menu Bar"
    case belowMenuBar = "Below Menu Bar"
    case floatingIsland = "Floating Island"

    public var id: String { rawValue }
}

/// Idle content options.
public enum ClipNotchIdleContent: String, CaseIterable, Identifiable, Codable, Sendable {
    case minimalIcon = "Minimal Icon"
    case empty = "Completely Empty"

    public var id: String { rawValue }
}

/// Base notch sizing presets.
public enum ClipNotchSize: String, CaseIterable, Identifiable, Codable, Sendable, Comparable {
    case compact = "Compact"
    case normal = "Normal"
    case large = "Large"
    case extraLarge = "Extra Large"
    case ultraWide = "Ultra Wide"
    case studio = "Studio / Max"

    public var id: String { rawValue }

    private var rank: Int {
        switch self {
        case .compact: return 1
        case .normal: return 2
        case .large: return 3
        case .extraLarge: return 4
        case .ultraWide: return 5
        case .studio: return 6
        }
    }

    public static func < (lhs: ClipNotchSize, rhs: ClipNotchSize) -> Bool {
        lhs.rank < rhs.rank
    }

    public var idleDimensions: CGSize {
        switch self {
        case .compact: return CGSize(width: 184 * 1.12, height: 34 * 1.12)
        case .normal: return CGSize(width: 224 * 1.12, height: 36 * 1.12)
        case .large: return CGSize(width: 260 * 1.12, height: 38 * 1.12)
        case .extraLarge: return CGSize(width: 310 * 1.12, height: 41 * 1.12)
        case .ultraWide: return CGSize(width: 390 * 1.12, height: 43 * 1.12)
        case .studio: return CGSize(width: 480 * 1.12, height: 45 * 1.12)
        }
    }

    public var bottomCornerRadius: CGFloat {
        switch self {
        case .compact: return 14 * 1.12
        case .normal: return 16 * 1.12
        case .large: return 17 * 1.12
        case .extraLarge: return 18 * 1.12
        case .ultraWide: return 19 * 1.12
        case .studio: return 20 * 1.12
        }
    }

    public var topWingRadius: CGFloat {
        switch self {
        case .compact: return 9 * 1.12
        case .normal: return 10 * 1.12
        case .large: return 11 * 1.12
        case .extraLarge: return 12 * 1.12
        case .ultraWide: return 13 * 1.12
        case .studio: return 14 * 1.12
        }
    }
}
