import AppKit
import SwiftUI

@MainActor
final class RestWindowController {
    private var windows: [NSWindow] = []

    func present(message: String, endsAt: Date, onSkip: @escaping () -> Void) {
        dismiss()

        for screen in NSScreen.screens {
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
                message: message,
                endsAt: endsAt,
                onSkip: onSkip
            )
            window.contentView = NSHostingView(rootView: view)
            window.makeKeyAndOrderFront(nil)
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
