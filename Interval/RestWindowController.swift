import AppKit
import SwiftUI

@MainActor
final class RestWindowController {
    private var windows: [NSWindow] = []

    func present(manager: IntervalManager, message: String, snoozeMinutes: Double, allowSkip: Bool, allScreens: Bool, onSkip: @escaping () -> Void, onSnooze: @escaping () -> Void) {
        dismiss()

        let screens: [NSScreen] = allScreens
            ? NSScreen.screens
            : [NSScreen.main ?? NSScreen.screens.first].compactMap { $0 }

        for (index, screen) in screens.enumerated() {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.level = .screenSaver
            window.collectionBehavior = [
                .canJoinAllSpaces,
                .fullScreenAuxiliary,
                .stationary,
                .ignoresCycle
            ]
            window.isReleasedWhenClosed = false
            window.ignoresMouseEvents = false
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true

            let view = RestView(
                manager: manager,
                message: message,
                snoozeMinutes: snoozeMinutes,
                allowSkip: allowSkip,
                onSkip: onSkip,
                onSnooze: onSnooze
            )
            window.contentView = NSHostingView(rootView: view)

            // Pin window to its target screen. The `screen:` init parameter is
            // only a hint for backing scale; without an explicit setFrame the
            // window can land on the main display, leaving other screens blank.
            window.setFrame(screen.frame, display: true)

            // Only the first window becomes key — making each one key in turn
            // causes the previous window's makeKey to be undone, which can
            // result in only the last-created window actually being ordered in.
            if index == 0 {
                window.makeKeyAndOrderFront(nil)
            } else {
                window.orderFrontRegardless()
            }
            windows.append(window)
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    func dismiss() {
        for window in windows {
            window.orderOut(nil)
        }
        windows.removeAll()
    }
}
