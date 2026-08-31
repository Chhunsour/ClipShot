import Foundation
import AppKit
import SwiftUI

/// OCR result capsule inside ClipNotch.
public struct ClipNotchOCRView: View {
    let text: String
    let onOpenFullText: () -> Void
    let onClose: () -> Void

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 11))

            Text("\(text.count) chars copied")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)

            Button(action: onOpenFullText) {
                Text("View")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .help("Open recognized text")

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
            .help("Dismiss")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
    }
}

/// Color Picker result capsule inside ClipNotch.
public struct ClipNotchColorView: View {
    let hex: String
    let rgb: String
    let hsl: String
    let onClose: () -> Void

    @State private var showingFormatMenu = false

    public var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: hex))
                .frame(width: 14, height: 14)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.white.opacity(0.3), lineWidth: 1))

            Text(hex)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white)

            Text("✓ Copied")
                .font(.system(size: 10))
                .foregroundColor(.green)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
            .help("Dismiss")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
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
