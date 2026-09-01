import Foundation
import AppKit
import SwiftUI

/// OCR result capsule inside ClipNotch.
public struct ClipNotchOCRView: View {
    let text: String
    let onOpenFullText: () -> Void
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false
    @State private var isViewHovered = false
    @State private var isCloseHovered = false

    public var body: some View {
        HStack(spacing: 7) {
            // Nested status icon: violet core with checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 8.5, weight: .heavy))
                .foregroundStyle(.black)
                .frame(width: 16, height: 16)
                .background(Circle().fill(Color.purple))
                .scaleEffect(revealed ? 1 : 0.7)

            Text("\(text.count) chars copied")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .offset(x: revealed ? 0 : -2)

            Spacer(minLength: 2)

            Button(action: onOpenFullText) {
                Text("View")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(isViewHovered ? 1.0 : 0.85))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.purple.opacity(isViewHovered ? 0.35 : 0.18))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.purple.opacity(isViewHovered ? 0.55 : 0.28), lineWidth: 0.6)
                    )
            }
            .buttonStyle(.plain)
            .help("Open recognized text")
            .accessibilityLabel("View recognized text")
            .onHover { isViewHovered = $0 }

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundStyle(.white.opacity(isCloseHovered ? 0.9 : 0.55))
                    .frame(width: 18, height: 18)
                    .background(Circle().fill(Color.white.opacity(isCloseHovered ? 0.14 : 0.06)))
            }
            .buttonStyle(.plain)
            .help("Dismiss")
            .accessibilityLabel("Dismiss OCR result")
            .onHover { isCloseHovered = $0 }
        }
        .padding(.horizontal, 8)
        .frame(height: 28)
        .background(
            Capsule(style: .continuous)
                .fill(Color.purple.opacity(0.08))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.purple.opacity(revealed ? 0.22 : 0.55), lineWidth: 0.7)
                .scaleEffect(revealed ? 1 : 0.88)
        )
        .padding(.horizontal, 4)
        .frame(width: 240, height: 34)
        .opacity(revealed ? 1 : 0)
        .onAppear {
            if reduceMotion {
                revealed = true
            } else {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.76)) {
                    revealed = true
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

/// Color Picker result capsule inside ClipNotch.
public struct ClipNotchColorView: View {
    let hex: String
    let rgb: String
    let hsl: String
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false
    @State private var isCloseHovered = false

    public var body: some View {
        let sampledColor = Color(hex: hex)

        HStack(spacing: 7) {
            // Machined swatch with specular border
            RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                .fill(sampledColor)
                .frame(width: 14, height: 14)
                .overlay(
                    RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                        .stroke(Color.white.opacity(0.35), lineWidth: 0.75)
                )
                .shadow(color: sampledColor.opacity(0.4), radius: 2)
                .scaleEffect(revealed ? 1 : 0.7)

            Text(hex)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)

            HStack(spacing: 2.5) {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                Text("Copied")
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
            }
            .foregroundStyle(Color.green.opacity(0.9))

            Spacer(minLength: 2)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundStyle(.white.opacity(isCloseHovered ? 0.9 : 0.55))
                    .frame(width: 18, height: 18)
                    .background(Circle().fill(Color.white.opacity(isCloseHovered ? 0.14 : 0.06)))
            }
            .buttonStyle(.plain)
            .help("Dismiss")
            .accessibilityLabel("Dismiss color result")
            .onHover { isCloseHovered = $0 }
        }
        .padding(.horizontal, 8)
        .frame(height: 28)
        .background(
            Capsule(style: .continuous)
                .fill(sampledColor.opacity(0.08))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(sampledColor.opacity(revealed ? 0.25 : 0.6), lineWidth: 0.7)
                .scaleEffect(revealed ? 1 : 0.88)
        )
        .padding(.horizontal, 4)
        .frame(width: 200, height: 34)
        .opacity(revealed ? 1 : 0)
        .onAppear {
            if reduceMotion {
                revealed = true
            } else {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.76)) {
                    revealed = true
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

extension Color {
    init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch cleanHex.count {
        case 3:
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
