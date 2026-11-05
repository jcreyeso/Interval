import SwiftUI

struct MenuBarLabel: View {
    let manager: IntervalManager
    let settings: IntervalSettings

    var body: some View {
        HStack(spacing: 4) {
            if settings.showTimerInMenuBar, manager.phase != .idle {
                Text(manager.menuBarRemaining)
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
}
