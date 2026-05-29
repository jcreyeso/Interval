import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct IntervalApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var settings = IntervalSettings.shared
    @State private var manager = IntervalManager()

    var body: some Scene {
        WindowGroup("Interval", id: "main") {
            ContentView(manager: manager, settings: settings)
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView(settings: settings)
        }

        MenuBarExtra {
            MenuBarContent(manager: manager, settings: settings)
        } label: {
            MenuBarLabel(manager: manager, settings: settings)
        }
    }
}

// MenuBarContent intentionally does NOT read manager.displayRemaining.
// That property updates every second and would cause the dropdown to rebuild
// on every tick, making it flicker and swallow clicks while open.
struct MenuBarContent: View {
    @Bindable var manager: IntervalManager
    let settings: IntervalSettings
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open Interval") {
            if let existing = NSApp.windows.first(where: { $0.title == "Interval" }) {
                if existing.isMiniaturized { existing.deminiaturize(nil) }
                existing.makeKeyAndOrderFront(nil)
            } else {
                openWindow(id: "main")
            }
            NSApp.activate(ignoringOtherApps: true)
        }

        Divider()

        switch manager.phase {
        case .idle:
            Text("Not running")
            Button("Start") { manager.start() }

        case .working:
            Text(manager.isPaused ? "Focus — paused (\(pauseReasonText))" : "Focus time")
            Button("Rest now") { manager.restNow() }
            Button("Stop") { manager.stop() }

        case .resting:
            Text("Resting")
            Button("Skip rest") { manager.skipRest() }
            Button("Stop") { manager.stop() }
        }

        Divider()

        Button("Settings…") { openSettings() }
            .keyboardShortcut(",", modifiers: .command)

        Button("Quit Interval") { NSApp.terminate(nil) }
            .keyboardShortcut("q", modifiers: .command)
    }

    private var pauseReasonText: String {
        switch manager.pauseReason {
        case .screenLocked: "screen locked"
        case .userIdle:     "idle"
        case .userActive:   "still active"
        case .none:         ""
        }
    }
}
