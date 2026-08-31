import Foundation
import AppKit
import CoreGraphics

/// Stable identifier and metadata for a physical or virtual display.
public struct DisplayIdentifier: Identifiable, Codable, Equatable, Sendable {
    public let id: String // UUID or generated unique hardware string
    public let name: String
    public let directDisplayID: CGDirectDisplayID
    public let frame: CGRect
    public let visibleFrame: CGRect
    public let scaleFactor: CGFloat
    public let isMain: Bool

    public init(
        id: String,
        name: String,
        directDisplayID: CGDirectDisplayID,
        frame: CGRect,
        visibleFrame: CGRect,
        scaleFactor: CGFloat,
        isMain: Bool
    ) {
        self.id = id
        self.name = name
        self.directDisplayID = directDisplayID
        self.frame = frame
        self.visibleFrame = visibleFrame
        self.scaleFactor = scaleFactor
        self.isMain = isMain
    }

    public var resolutionString: String {
        let w = Int(round(frame.width * scaleFactor))
        let h = Int(round(frame.height * scaleFactor))
        return "\(w) × \(h)"
    }

    public var displayName: String {
        if isMain {
            return "\(name) (Main Display)"
        }
        return "\(name) (\(resolutionString))"
    }
}
