import SwiftUI

struct ContentView: View {
    @Bindable var manager: IntervalManager
    let settings: IntervalSettings

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(.tint)
                .symbolEffect(.pulse, isActive: manager.phase != .idle && !manager.isPaused)
                .frame(height: 72)

            Text(statusText)
                .font(.title2.weight(.semibold))

            if manager.phase != .idle {
                Text(format(manager.displayRemaining))
                    .font(.system(size: 56, weight: .light, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(manager.isPaused ? .secondary : .primary)
            } else {
                Text("--:--")
                    .font(.system(size: 56, weight: .light, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            pauseBadge
                .frame(height: 20)

            HStack(spacing: 12) {
                if manager.phase == .idle {
                    Button("Start") { manager.start() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .keyboardShortcut(.defaultAction)
                } else {
                    Button("Stop") { manager.stop() }
                        .controlSize(.large)
                    if manager.phase == .working {
                        Button("Rest now") { manager.restNow() }
                            .controlSize(.large)
                    } else {
                        Button("Skip") { manager.skipRest() }
                            .controlSize(.large)
                    }
                }
            }

            Text("Work \(Int(settings.workMinutes)) min  ·  Rest \(Int(settings.restMinutes)) min  ·  Idle \(Int(settings.idleThresholdSeconds))s")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(width: 380, height: 420)
    }

    @ViewBuilder
    private var pauseBadge: some View {
        if manager.isPaused, let reason = manager.pauseReason {
            HStack(spacing: 6) {
                Image(systemName: reason == .screenLocked ? "lock.fill" : "pause.circle.fill")
                Text(pauseText(for: reason))
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .transition(.opacity)
        } else {
            EmptyView()
        }
    }

    private func pauseText(for reason: IntervalManager.PauseReason) -> String {
        switch reason {
        case .screenLocked: "Paused — screen locked"
        case .userIdle: "Paused — you're idle"
        case .userActive: "Paused — finish your rest"
        }
    }

    private var statusText: String {
        switch manager.phase {
        case .idle: "Ready"
        case .working: "Focus time"
        case .resting: "Resting"
        }
    }

    private var iconName: String {
        switch manager.phase {
        case .idle: "timer"
        case .working: manager.isPaused ? "pause.circle" : "brain.head.profile"
        case .resting: "leaf.fill"
        }
    }

    private func format(_ t: TimeInterval) -> String {
        let total = Int(t.rounded())
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}

#Preview {
    ContentView(manager: IntervalManager(), settings: .shared)
}
