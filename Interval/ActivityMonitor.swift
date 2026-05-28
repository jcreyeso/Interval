import AppKit
import CoreGraphics
import Observation

@MainActor
protocol ActivityMonitoring {
    var isScreenLocked: Bool { get }
    var secondsSinceLastInput: TimeInterval { get }
}

@MainActor
@Observable
final class ActivityMonitor: ActivityMonitoring {
    private(set) var isScreenLocked: Bool = false

    init() {
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(
            forName: Notification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.isScreenLocked = true }
        }
        dnc.addObserver(
            forName: Notification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.isScreenLocked = false }
        }
    }

    /// Seconds since any keyboard/mouse/HID input across all sessions.
    /// Works inside the App Sandbox without Input Monitoring permission.
    var secondsSinceLastInput: TimeInterval {
        let anyEvent = CGEventType(rawValue: ~0)!
        return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyEvent)
    }
}
