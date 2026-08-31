import Foundation
import AppKit
import SwiftUI

/// Floating glass-style toolbar displayed in the full-screen capture overlay.
public struct CaptureToolbarView: View {
    @Binding var selectedMode: CaptureMode
    let onCaptureTriggered: () -> Void
    let onCancel: () -> Void
    let onOpenSettings: () -> Void

    public var body: some View {
        HStack(spacing: 8) {
            // Mode Selectors
            ForEach(CaptureMode.allCases) { mode in
                Button(action: { selectedMode = mode }) {
                    VStack(spacing: 3) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 14, weight: .medium))
                        Text(mode.title)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(selectedMode == mode ? .white : .primary)
                    .frame(width: 48, height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(selectedMode == mode ? Color.accentColor : Color.clear)
                    )
                }
                .buttonStyle(.plain)
                .help("\(mode.title) Capture")
            }

            Divider()
                .frame(height: 24)
                .padding(.horizontal, 4)

            // Settings Button
            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .frame(width: 32, height: 38)
            }
            .buttonStyle(.plain)
            .help("ClipShot Settings")

            // Cancel / Close (Esc)
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 32, height: 38)
            }
            .buttonStyle(.plain)
            .help("Cancel (Esc)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

/// NSVisualEffectView wrapper for SwiftUI.
public struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .withinWindow

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
