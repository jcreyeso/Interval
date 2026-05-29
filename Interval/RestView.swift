import SwiftUI

struct RestView: View {
    let manager: IntervalManager
    let message: String
    let snoozeMinutes: Double
    let allowSkip: Bool
    let onSkip: () -> Void
    let onSnooze: () -> Void

    private var isPaused: Bool {
        manager.isPaused && manager.pauseReason == .userActive
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.20, green: 0.25, blue: 0.55).opacity(0.78),
                    Color(red: 0.45, green: 0.30, blue: 0.65).opacity(0.78),
                    Color(red: 0.20, green: 0.45, blue: 0.65).opacity(0.78)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .background(.ultraThinMaterial)
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 180, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.95))
                    .symbolEffect(.pulse, options: .repeating, isActive: !isPaused)
                    .shadow(color: .black.opacity(0.25), radius: 24, y: 6)

                Text(message)
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 80)
                    .shadow(color: .black.opacity(0.25), radius: 12, y: 4)

                Text(formatTime(manager.displayRemaining))
                    .font(.system(size: 72, weight: .light, design: .monospaced))
                    .foregroundStyle(.white.opacity(isPaused ? 0.55 : 0.95))
                    .monospacedDigit()

                if isPaused {
                    HStack(spacing: 8) {
                        Image(systemName: "pause.circle.fill")
                        Text("Paused — stop using the computer to rest")
                    }
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.12), in: Capsule())
                }

                HStack(spacing: 16) {
                    if allowSkip {
                        Button(action: onSnooze) {
                            Text("Delay \(Int(snoozeMinutes)) min")
                                .font(.title3.weight(.medium))
                                .padding(.horizontal, 28)
                                .padding(.vertical, 14)
                                .foregroundStyle(.white.opacity(0.85))
                                .background(.white.opacity(0.12), in: Capsule())
                                .overlay(
                                    Capsule().strokeBorder(.white.opacity(0.30), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: onSkip) {
                        Text("Skip")
                            .font(.title3.weight(.medium))
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                            .background(.white.opacity(0.18), in: Capsule())
                            .overlay(
                                Capsule().strokeBorder(.white.opacity(0.45), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 16)
            }
            .padding(.vertical, 60)
        }
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let total = Int(t.rounded())
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}

#Preview {
    RestView(
        manager: IntervalManager(),
        message: "Time to rest.\nStand up, stretch, breathe.",
        snoozeMinutes: 5,
        allowSkip: true,
        onSkip: {},
        onSnooze: {}
    )
    .frame(width: 1200, height: 800)
}
