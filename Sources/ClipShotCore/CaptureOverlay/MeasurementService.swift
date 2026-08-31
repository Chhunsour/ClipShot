import Foundation
import CoreGraphics

/// Service for on-screen pixel measurement, distance calculation, and alignment guides.
public final class MeasurementService: Sendable {
    public static let shared = MeasurementService()

    public init() {}

    /// Calculates the Euclidean distance between two points in screen pixels.
    public func distance(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(dx * dx + dy * dy)
    }

    /// Formats the measurement string for a rectangle.
    public func formatRectDimensions(_ rect: CGRect) -> String {
        let w = Int(round(abs(rect.width)))
        let h = Int(round(abs(rect.height)))
        return "\(w) × \(h) px"
    }

    /// Formats distance between two points.
    public func formatDistance(from p1: CGPoint, to p2: CGPoint) -> String {
        let dist = Int(round(distance(from: p1, to: p2)))
        let dx = Int(round(abs(p2.x - p1.x)))
        let dy = Int(round(abs(p2.y - p1.y)))

        if dx == 0 { return "\(dy) px (V)" }
        if dy == 0 { return "\(dx) px (H)" }
        return "\(dist) px (Δx: \(dx), Δy: \(dy))"
    }
}
