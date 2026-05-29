import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Without a delegate that opts in via willPresent, foreground notifications
        // are silently suppressed on macOS — so the pre-rest heads-up never shows.
        UNUserNotificationCenter.current().delegate = self

        // SwiftUI's WindowGroup restores any window that was open at last quit.
        // We want a menu-bar-only launch — close any auto-restored main windows.
        DispatchQueue.main.async {
            for window in NSApp.windows where window.title == "Interval" {
                window.close()
            }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillClose(_:)),
            name: NSWindow.willCloseNotification,
            object: nil
        )
    }

    static func showInDock() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func windowWillClose(_ note: Notification) {
        // A user-facing window is about to disappear. After the close completes,
        // if no other titled windows remain, drop back to menu-bar-only.
        DispatchQueue.main.async {
            let stillOpen = NSApp.windows.contains { window in
                window.isVisible && window.styleMask.contains(.titled)
            }
            if !stillOpen {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        false
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
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
            AppDelegate.showInDock()
            if let existing = NSApp.windows.first(where: { $0.title == "Interval" }) {
                if existing.isMiniaturized { existing.deminiaturize(nil) }
                existing.makeKeyAndOrderFront(nil)
            } else {
                openWindow(id: "main")
            }
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
            Button("Skip") { manager.skipRest() }
            Button("Stop") { manager.stop() }
        }

        Divider()

        Button("Settings…") {
            AppDelegate.showInDock()
            openSettings()
        }
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
