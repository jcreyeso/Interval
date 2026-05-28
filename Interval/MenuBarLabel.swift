import SwiftUI

struct MenuBarLabel: View {
    let manager: IntervalManager
    let settings: IntervalSettings

    var body: some View {
        HStack(spacing: 4) {
            if settings.showTimerInMenuBar, manager.phase != .idle {
                Text(format(manager.displayRemaining))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .monospacedDigit()
            }
            Image(systemName: iconName)
        }
    }

    private var iconName: String {
        switch manager.phase {
        case .idle:    "timer"
        case .working: manager.isPaused ? "pause.circle" : "brain.head.profile"
        case .resting: "leaf.fill"
        }
    }

    private func format(_ t: TimeInterval) -> String {
        let total = Int(t.rounded())
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
