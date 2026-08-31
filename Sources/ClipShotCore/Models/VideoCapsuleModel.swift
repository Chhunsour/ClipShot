import Foundation
import CoreGraphics
import AppKit

/// Video scaling mode inside the ClipNotch Video Capsule.
public enum VideoScalingMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case fit = "Fit"
    case fill = "Fill"
    case original = "16:9"

    public var id: String { rawValue }
}

/// Capsule window size setting.
public enum VideoCapsuleSize: String, CaseIterable, Identifiable, Codable, Sendable {
    case small = "Small"     // ~260 × 146
    case medium = "Medium"   // ~360 × 203
    case large = "Large"     // ~480 × 270

    public var id: String { rawValue }

    public var dimensions: CGSize {
        switch self {
        case .small: return CGSize(width: 280, height: 158)
        case .medium: return CGSize(width: 360, height: 203)
        case .large: return CGSize(width: 480, height: 270)
        }
    }
}

/// Model representing an active or configured Video Capsule stream.
public struct VideoCapsuleModel: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let windowID: CGWindowID
    public let appName: String
    public let windowTitle: String
    public var cropRect: CGRect?
    public var scalingMode: VideoScalingMode
    public var targetFPS: Int
    public var isPoppedOut: Bool

    public init(
        id: UUID = UUID(),
        windowID: CGWindowID,
        appName: String,
        windowTitle: String,
        cropRect: CGRect? = nil,
        scalingMode: VideoScalingMode = .fit,
        targetFPS: Int = 30,
        isPoppedOut: Bool = false
    ) {
        self.id = id
        self.windowID = windowID
        self.appName = appName
        self.windowTitle = windowTitle
        self.cropRect = cropRect
        self.scalingMode = scalingMode
        self.targetFPS = targetFPS
        self.isPoppedOut = isPoppedOut
    }

    public var displayTitle: String {
        if !windowTitle.isEmpty {
            return "\(appName) — \(windowTitle)"
        }
        return appName
    }
}
