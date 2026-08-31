import Foundation
import AppKit
import SwiftUI

/// Grouped, machined quick-action rail inside ClipNotch.
public struct ClipNotchQuickActionsView: View {
    let onArea: () -> Void
    let onWindow: () -> Void
    let onOCR: () -> Void
    let onRecord: () -> Void
    let onColor: () -> Void
    let onMore: () -> Void

    public var body: some View {
        HStack(spacing: 3) {
            NotchQuickIconButton(icon: "crop", tint: .cyan, label: "Capture Area", delay: 0, action: onArea)
            NotchQuickIconButton(icon: "macwindow", tint: .cyan, label: "Capture Window", delay: 0.025, action: onWindow)
            NotchQuickIconButton(icon: "text.viewfinder", tint: .purple, label: "OCR Area", delay: 0.05, action: onOCR)

            NotchQuickDivider()

            NotchQuickIconButton(icon: "record.circle", tint: .red, label: "Record Screen", delay: 0.075, action: onRecord)
            NotchQuickIconButton(icon: "eyedropper", tint: .orange, label: "Sample Color", delay: 0.1, action: onColor)

            NotchQuickDivider()

            NotchQuickIconButton(icon: "doc.on.clipboard", tint: .mint, label: "Clipboard and Captures", delay: 0.15, action: onMore)
        }
        .padding(.horizontal, 7)
        .frame(height: 31)
        .background(quickRail)
        .padding(.horizontal, 5)
        .frame(height: 38)
        .transition(.opacity)
    }

    private var quickRail: some View {
        Capsule(style: .continuous)
            .fill(.white.opacity(0.045))
            .overlay {
                Capsule(style: .continuous)
                    .stroke(.white.opacity(0.09), lineWidth: 0.6)
            }
    }
}

private struct NotchQuickDivider: View {
    var body: some View {
        Capsule()
            .fill(.white.opacity(0.11))
            .frame(width: 1, height: 13)
            .padding(.horizontal, 1)
            .accessibilityHidden(true)
    }
}

struct NotchQuickIconButton: View {
    let icon: String
    let tint: Color
    let label: String
    let delay: Double
    let action: () -> Void

    @State private var isHovered = false
    @State private var isRevealed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            QuickActionGlyph(icon: icon, tint: tint, isHovered: isHovered)
                .scaleEffect(isHovered && !reduceMotion ? 1.045 : 1)
                .offset(y: isHovered && !reduceMotion ? -0.5 : 0)
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
        .onHover { isHovered = $0 }
        .opacity(isRevealed ? 1 : 0)
        .offset(y: isRevealed ? 0 : -4)
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.78), value: isHovered)
        .onAppear {
            guard !reduceMotion else {
                isRevealed = true
                return
            }
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82).delay(delay)) {
                isRevealed = true
            }
        }
    }
}

private struct QuickActionGlyph: View {
    let icon: String
    let tint: Color
    let isHovered: Bool

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 12, weight: .medium))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(isHovered ? .white : .white.opacity(0.74))
            .frame(width: 31, height: 27)
            .background {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isHovered ? Color.white.opacity(0.09) : .clear)
            }
            .overlay(alignment: .bottom) {
                Capsule()
                    .fill(tint.opacity(isHovered ? 0.9 : 0))
                    .frame(width: 8, height: 1.5)
                    .offset(y: -2)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(.white.opacity(isHovered ? 0.13 : 0), lineWidth: 0.6)
            }
            .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}
