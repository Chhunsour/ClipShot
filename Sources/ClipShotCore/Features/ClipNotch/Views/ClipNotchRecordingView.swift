import Foundation
import AppKit
import SwiftUI

/// Ultra-compact screen recording indicator for ClipNotch with physical-style status rail and breathing live dot.
public struct ClipNotchRecordingView: View {
    let durationSeconds: Int
    let isPaused: Bool
    let onPauseResume: () -> Void
    let onStop: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false
    @State private var isPauseHovered = false
    @State private var isStopHovered = false

    private var formattedDuration: String {
        let mins = durationSeconds / 60
        let secs = durationSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    public var body: some View {
        HStack(spacing: 5) {
            HStack(spacing: 3) {
                liveDot
                Text(isPaused ? "PAUSE" : "REC")
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .foregroundColor(isPaused ? .yellow : .red)
            }

            Text(formattedDuration)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white)

            if AppSettings.shared.recordMicrophone {
                Image(systemName: "mic.fill")
                    .font(.system(size: 8.5))
                    .foregroundColor(.white.opacity(0.8))
                    .accessibilityLabel("Microphone active")
            }

            Spacer(minLength: 0)

            Capsule()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: 12)
                .accessibilityHidden(true)

            HStack(spacing: 3) {
                controlButton(
                    icon: isPaused ? "play.fill" : "pause.fill",
                    tint: .white,
                    label: isPaused ? "Resume recording" : "Pause recording",
                    isHovered: $isPauseHovered,
                    action: onPauseResume
                )
                .contentTransition(.symbolEffect(.replace))
                .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: isPaused)

                controlButton(
                    icon: "stop.fill",
                    tint: .red,
                    label: "Stop recording",
                    isHovered: $isStopHovered,
                    action: onStop
                )
            }
        }
        .padding(.horizontal, 6)
        .frame(height: 28)
        .background(
            Capsule(style: .continuous)
                .fill(isPaused ? Color.yellow.opacity(0.06) : Color.red.opacity(0.06))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(isPaused ? Color.yellow.opacity(0.18) : Color.red.opacity(0.18), lineWidth: 0.6)
        )
        .padding(.horizontal, 4)
        .frame(height: 34)
        .transition(.opacity)
        .onAppear {
            updatePulsing()
        }
        .onChange(of: isPaused) {
            updatePulsing()
        }
        .onChange(of: reduceMotion) {
            updatePulsing()
        }
        .accessibilityElement(children: .contain)
    }

    private var liveDot: some View {
        ZStack {
            if !isPaused {
                Circle()
                    .fill(Color.red.opacity(0.45))
                    .frame(width: 6, height: 6)
                    .scaleEffect(isPulsing && !reduceMotion ? 2.0 : 1.0)
                    .opacity(isPulsing && !reduceMotion ? 0.1 : 0.75)
                    .animation(
                        !reduceMotion && !isPaused
                            ? .smooth(duration: 1.1).repeatForever(autoreverses: true)
                            : .default,
                        value: isPulsing
                    )
            }

            Circle()
                .fill(isPaused ? Color.yellow : Color.red)
                .frame(width: 6, height: 6)
                .shadow(color: isPaused ? Color.yellow.opacity(0.5) : Color.red.opacity(0.6), radius: 2)
        }
        .frame(width: 14, height: 14)
    }

    private func updatePulsing() {
        isPulsing = false
        guard !isPaused, !reduceMotion else { return }
        DispatchQueue.main.async {
            isPulsing = true
        }
    }

    private func controlButton(
        icon: String,
        tint: Color,
        label: String,
        isHovered: Binding<Bool>,
        action: @escaping () -> Void
    ) -> some View {
        let hovered = isHovered.wrappedValue
        return Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(tint.opacity(hovered ? 1 : 0.9))
                .frame(width: 20, height: 20)
                .background(Circle().fill(tint.opacity(hovered ? 0.20 : 0.08)))
                .overlay(Circle().stroke(tint.opacity(hovered ? 0.32 : 0.12), lineWidth: 0.5))
                .scaleEffect(hovered && !reduceMotion ? 1.06 : 1)
                .animation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.76), value: hovered)
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
        .onHover { isHovered.wrappedValue = $0 }
    }
}
