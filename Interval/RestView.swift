import SwiftUI

struct RestPalette {
    let colors: [Color]

    static let all: [RestPalette] = [
        // Twilight indigo
        RestPalette(colors: [
            Color(red: 0.20, green: 0.25, blue: 0.55),
            Color(red: 0.45, green: 0.30, blue: 0.65),
            Color(red: 0.20, green: 0.45, blue: 0.65)
        ]),
        // Forest moss
        RestPalette(colors: [
            Color(red: 0.18, green: 0.36, blue: 0.32),
            Color(red: 0.30, green: 0.50, blue: 0.40),
            Color(red: 0.45, green: 0.58, blue: 0.42)
        ]),
        // Ocean drift
        RestPalette(colors: [
            Color(red: 0.10, green: 0.30, blue: 0.50),
            Color(red: 0.18, green: 0.50, blue: 0.62),
            Color(red: 0.40, green: 0.68, blue: 0.72)
        ]),
        // Lavender dusk
        RestPalette(colors: [
            Color(red: 0.36, green: 0.28, blue: 0.55),
            Color(red: 0.55, green: 0.42, blue: 0.68),
            Color(red: 0.72, green: 0.60, blue: 0.78)
        ]),
        // Warm sunset
        RestPalette(colors: [
            Color(red: 0.60, green: 0.30, blue: 0.40),
            Color(red: 0.80, green: 0.45, blue: 0.40),
            Color(red: 0.92, green: 0.65, blue: 0.45)
        ]),
        // Sand & sage
        RestPalette(colors: [
            Color(red: 0.55, green: 0.58, blue: 0.50),
            Color(red: 0.72, green: 0.70, blue: 0.58),
            Color(red: 0.85, green: 0.78, blue: 0.65)
        ]),
        // Northern aurora
        RestPalette(colors: [
            Color(red: 0.10, green: 0.28, blue: 0.42),
            Color(red: 0.20, green: 0.55, blue: 0.55),
            Color(red: 0.40, green: 0.70, blue: 0.55)
        ]),
        // Rose quartz
        RestPalette(colors: [
            Color(red: 0.55, green: 0.38, blue: 0.50),
            Color(red: 0.78, green: 0.55, blue: 0.62),
            Color(red: 0.90, green: 0.72, blue: 0.72)
        ])
    ]

    static func random() -> RestPalette {
        all.randomElement() ?? all[0]
    }
}

struct RestView: View {
    let manager: IntervalManager
    let message: String
    let snoozeMinutes: Double
    let allowSkip: Bool
    let onSkip: () -> Void
    let onSnooze: () -> Void
    let palette: RestPalette

    private var isPaused: Bool {
        manager.isPaused && manager.pauseReason == .userActive
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: palette.colors.map { $0.opacity(0.78) },
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
        onSnooze: {},
        palette: .random()
    )
    .frame(width: 1200, height: 800)
}
