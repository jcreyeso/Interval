import SwiftUI

struct RestView: View {
    let message: String
    let endsAt: Date
    let onSkip: () -> Void

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
                    .symbolEffect(.pulse, options: .repeating)
                    .shadow(color: .black.opacity(0.25), radius: 24, y: 6)

                Text(message)
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 80)
                    .shadow(color: .black.opacity(0.25), radius: 12, y: 4)

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let remaining = max(0, endsAt.timeIntervalSince(context.date))
                    Text(formatTime(remaining))
                        .font(.system(size: 72, weight: .light, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.95))
                        .monospacedDigit()
                }

                Button(action: onSkip) {
                    Text("Skip rest")
                        .font(.title3.weight(.medium))
                        .padding(.horizontal, 36)
                        .padding(.vertical, 14)
                        .foregroundStyle(.white)
                        .background(.white.opacity(0.18), in: Capsule())
                        .overlay(
                            Capsule().strokeBorder(.white.opacity(0.45), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
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
        message: "Time to rest.\nStand up, stretch, breathe.",
        endsAt: Date().addingTimeInterval(5 * 60),
        onSkip: {}
    )
    .frame(width: 1200, height: 800)
}
