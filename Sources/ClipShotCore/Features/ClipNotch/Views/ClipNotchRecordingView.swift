import Foundation
import AppKit
import SwiftUI

/// Ultra-compact screen recording indicator for ClipNotch with Apple-style pulsating live dot.
public struct ClipNotchRecordingView: View {
    let durationSeconds: Int
    let isPaused: Bool
    let onPauseResume: () -> Void
    let onStop: () -> Void

    private var formattedDuration: String {
        let mins = durationSeconds / 60
        let secs = durationSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    public var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isPaused ? Color.yellow : Color.red)
                .frame(width: 7, height: 7)

            Text("REC")
                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                .foregroundColor(isPaused ? .yellow : .red)

            Text(formattedDuration)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white)

            if AppSettings.shared.recordMicrophone {
                Image(systemName: "mic.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.8))
            }

            Divider()
                .frame(height: 12)

            Button(action: onPauseResume) {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.white)
                    .padding(3)
                    .background(Circle().fill(Color.white.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .help(isPaused ? "Resume recording" : "Pause recording")

            Button(action: onStop) {
                Image(systemName: "stop.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.red)
                    .padding(3)
                    .background(Circle().fill(Color.white.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .help("Stop recording")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(height: 34)
        .transition(.opacity)
    }
}
