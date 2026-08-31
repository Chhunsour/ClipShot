import Foundation
import AppKit
import SwiftUI

/// Magnifying loupe view displaying zoomed pixels, crosshair, color swatch, and coordinates.
public struct PrecisionLoupeView: View {
    let magnifiedImage: CGImage?
    let targetColor: NSColor?
    let point: CGPoint

    public var body: some View {
        VStack(spacing: 4) {
            // Magnifier circle/rect
            ZStack {
                if let cg = magnifiedImage {
                    Image(decorative: cg, scale: 1.0)
                        .interpolation(.none) // Nearest-neighbor for crisp pixel grid
                        .resizable()
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Rectangle()
                        .fill(Color.black.opacity(0.8))
                        .frame(width: 96, height: 96)
                        .cornerRadius(8)
                }

                // Crosshair
                Path { path in
                    path.move(to: CGPoint(x: 48, y: 0))
                    path.addLine(to: CGPoint(x: 48, y: 96))
                    path.move(to: CGPoint(x: 0, y: 48))
                    path.addLine(to: CGPoint(x: 96, y: 48))
                }
                .stroke(Color.red.opacity(0.8), lineWidth: 1)

                // Center pixel highlight box
                Rectangle()
                    .stroke(Color.white, lineWidth: 1.5)
                    .frame(width: 8, height: 8)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)

            // Color & coordinate readout
            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    if let color = targetColor {
                        Circle()
                            .fill(Color(nsColor: color))
                            .frame(width: 10, height: 10)
                            .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1))

                        Text(ColorPickerService.shared.hexString(from: color))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }

                Text("X: \(Int(point.x))  Y: \(Int(point.y))")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.75))
            .cornerRadius(6)
        }
    }
}
