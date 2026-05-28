import SwiftUI

@main
struct IntervalApp: App {
    @State private var settings = IntervalSettings.shared
    @State private var manager = IntervalManager()

    var body: some Scene {
        WindowGroup("Interval") {
            ContentView(manager: manager, settings: settings)
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView(settings: settings)
        }

        MenuBarExtra("Interval", systemImage: menuBarIcon) {
            MenuBarContent(manager: manager, settings: settings)
        }
    }

    private var menuBarIcon: String {
        switch manager.phase {
        case .idle: "timer"
        case .working: "brain.head.profile"
        case .resting: "leaf.fill"
        }
    }
}

struct MenuBarContent: View {
    @Bindable var manager: IntervalManager
    let settings: IntervalSettings
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Group {
            switch manager.phase {
            case .idle:
                Text("Idle")
                Button("Start") { manager.start() }
            case .working:
                Text(remainingLabel(prefix: "Focus"))
                if manager.isPaused {
                    Text(pauseLabel).foregroundStyle(.secondary)
                }
                Button("Rest now") { manager.restNow() }
                Button("Stop") { manager.stop() }
            case .resting:
                Text(remainingLabel(prefix: "Rest"))
                Button("Skip rest") { manager.skipRest() }
                Button("Stop") { manager.stop() }
            }
        }

        Divider()

        Button("Settings…") { openSettings() }
            .keyboardShortcut(",", modifiers: .command)

        Button("Quit Interval") { NSApp.terminate(nil) }
            .keyboardShortcut("q", modifiers: .command)
    }

    private func remainingLabel(prefix: String) -> String {
        let total = Int(manager.displayRemaining.rounded())
        return String(format: "%@: %02d:%02d", prefix, total / 60, total % 60)
    }

    private var pauseLabel: String {
        switch manager.pauseReason {
        case .screenLocked: "(screen locked)"
        case .userIdle: "(idle)"
        case .none: ""
        }
    }
}
