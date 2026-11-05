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
                RestIllustration()

                Text(message)
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 80)
                    .shadow(color: .black.opacity(0.25), radius: 12, y: 4)

                RestCountdown(manager: manager, isPaused: isPaused)

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
}

// Its own view so the per-second displayRemaining read invalidates only this text,
// not the rest of the screen.
private struct RestCountdown: View {
    let manager: IntervalManager
    let isPaused: Bool

    var body: some View {
        Text(formatTime(manager.displayRemaining))
            .font(.system(size: 72, weight: .light, design: .monospaced))
            .foregroundStyle(.white.opacity(isPaused ? 0.55 : 0.95))
            .monospacedDigit()
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let total = Int(t.rounded())
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// Deliberately static: a repeating symbol effect here cost about 11% of a core even in
// a small test window. Drawn in white so it suits every RestPalette, and as vectors
// so it stays sharp at any backing scale.
struct RestIllustration: View {
    private let waterline = CGPoint(x: 160, y: 190)

    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 320, y: size.height / 240)
            drawHalo(in: &context)
            drawRipples(in: &context)
            // Back row first so the shorter front petals overlap it.
            drawPetals(angles: [-64, -32, 0, 32, 64], length: 118, width: 44, opacity: 0.55, in: &context)
            drawPetals(angles: [-80, -48, -16, 16, 48, 80], length: 92, width: 40, opacity: 0.95, in: &context)
        }
        .frame(width: 320, height: 240)
        .shadow(color: .black.opacity(0.18), radius: 16, y: 6)
        .accessibilityHidden(true)
    }

    private func drawHalo(in context: inout GraphicsContext) {
        let center = CGPoint(x: waterline.x, y: 118)
        let glow = Path(ellipseIn: CGRect(x: center.x - 118, y: center.y - 118, width: 236, height: 236))
        context.fill(glow, with: .radialGradient(
            Gradient(colors: [.white.opacity(0.42), .white.opacity(0)]),
            center: center,
            startRadius: 0,
            endRadius: 118
        ))
        for (radius, opacity) in [(72.0, 0.22), (92.0, 0.14), (112.0, 0.07)] {
            let ring = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            context.stroke(ring, with: .color(.white.opacity(opacity)), lineWidth: 1)
        }
    }

    private func drawRipples(in context: inout GraphicsContext) {
        for (radiusX, radiusY, opacity) in [(70.0, 9.0, 0.45), (108.0, 15.0, 0.25), (146.0, 21.0, 0.12)] {
            let center = CGPoint(x: waterline.x, y: waterline.y + 8)
            let ripple = Path(ellipseIn: CGRect(x: center.x - radiusX, y: center.y - radiusY, width: radiusX * 2, height: radiusY * 2))
            context.stroke(ripple, with: .color(.white.opacity(opacity)), lineWidth: 1.2)
        }
    }

    private func drawPetals(angles: [Double], length: CGFloat, width: CGFloat, opacity: Double, in context: inout GraphicsContext) {
        var petal = Path()
        petal.move(to: .zero)
        petal.addQuadCurve(to: CGPoint(x: 0, y: -length), control: CGPoint(x: width * 0.8, y: -length * 0.5))
        petal.addQuadCurve(to: .zero, control: CGPoint(x: -width * 0.8, y: -length * 0.5))

        // Outermost petals first, so each layer closes in toward the center.
        for angle in angles.sorted(by: { abs($0) > abs($1) }) {
            var layer = context
            layer.translateBy(x: waterline.x, y: waterline.y)
            layer.rotate(by: .degrees(angle))
            layer.fill(petal, with: .linearGradient(
                Gradient(colors: [.white.opacity(opacity), .white.opacity(opacity * 0.35)]),
                startPoint: CGPoint(x: 0, y: -length),
                endPoint: .zero
            ))
            layer.stroke(petal, with: .color(.white.opacity(opacity * 0.5)), lineWidth: 0.75)
        }
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
