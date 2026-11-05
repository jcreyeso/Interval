import Testing
import Foundation
import AppKit
@testable import Interval

@MainActor
private final class StubActivity: ActivityMonitoring {
    var isScreenLocked = false
    var secondsSinceLastInput: TimeInterval = 0
}

// Serialized because the sleep/wake tests post system-wide notifications that every
// live IntervalManager observes.
@MainActor
@Suite(.serialized)
struct IntervalTests {

    /// Verifies that when the rest interval expires the work counter restarts
    /// automatically — no user action required — even when the user was idle
    /// for the entire rest period (the realistic case).
    @Test func restCompletionRestartsWorkCounter() async throws {
        // 2 s work, 5 s rest. Rest is longer than the post-rest idle-reset
        // threshold so a stub idle value > restInteractionThreshold (2 s) can
        // still be < restDurationSeconds (5 s).
        let settings = IntervalSettings(workMinutes: 2 / 60, restMinutes: 5 / 60)
        let activity = StubActivity()
        // 3 s satisfies both: > restInteractionThreshold (rest counts down)
        // and < restDurationSeconds (post-rest stop check does not fire).
        activity.secondsSinceLastInput = 3
        let manager = IntervalManager(settings: settings, activity: activity)

        manager.start()

        // Work (2 s) + rest (5 s) ≈ 7 s. Wait 8 s with margin.
        try await Task.sleep(for: .seconds(8))

        #expect(manager.phase != .idle,
                "Manager must not stop itself after rest ends — no user action required")
        #expect(manager.phase == .working,
                "Manager should be in the working phase after the full work/rest cycle")

        manager.stop()
    }

    @Test func launchStartsTimerOnlyWhenEnabled() {
        let off = IntervalManager(
            settings: IntervalSettings(workMinutes: 1, restMinutes: 1, startOnLaunch: false),
            activity: StubActivity()
        )
        off.startOnLaunchIfEnabled()
        #expect(off.phase == .idle)

        let on = IntervalManager(
            settings: IntervalSettings(workMinutes: 1, restMinutes: 1, startOnLaunch: true),
            activity: StubActivity()
        )
        on.startOnLaunchIfEnabled()
        #expect(on.phase == .working)
        on.stop()
    }

    /// The menu bar must only redraw once a minute, until the final minute counts
    /// down in seconds.
    @Test(arguments: [
        (1800.0, "30m"), (1799.5, "30m"), (61.0, "2m"), (60.5, "2m"), (60.0, "1m"),
        (59.5, "1m"), (59.0, "59s"), (1.0, "1s"), (0.2, "1s")
    ])
    func menuBarTextFormatsRemainingTime(remaining: TimeInterval, expected: String) {
        #expect(IntervalManager.menuBarText(for: remaining) == expected)
    }

    @Test func menuBarTextFollowsCountdown() async throws {
        let settings = IntervalSettings(workMinutes: 62 / 60, restMinutes: 5 / 60)
        let manager = IntervalManager(settings: settings, activity: StubActivity())

        manager.start()
        #expect(manager.menuBarRemaining == "2m")

        try await Task.sleep(for: .seconds(4))
        #expect(manager.displayRemaining < 60)
        #expect(manager.menuBarRemaining.hasSuffix("s"))

        manager.stop()
    }

    private func postSleep() {
        NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.willSleepNotification, object: nil)
    }

    private func postWake() {
        NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.didWakeNotification, object: nil)
    }

    /// Macs usually sleep after being idle for a while, so the time away is the idle
    /// time plus the sleep, even when neither alone is longer than a rest.
    @Test func idleThenSleepLongerThanRestRestartsFocusSession() async throws {
        let settings = IntervalSettings(workMinutes: 1, restMinutes: 5 / 60)
        let activity = StubActivity()
        let manager = IntervalManager(settings: settings, activity: activity)
        manager.start()
        try await Task.sleep(for: .seconds(4))
        #expect(manager.displayRemaining < 58)

        // 3 s idle + 3 s asleep = 6 s away, against a 5 s rest.
        activity.secondsSinceLastInput = 3
        postSleep()
        try await Task.sleep(for: .seconds(3))
        activity.secondsSinceLastInput = 0
        postWake()
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.displayRemaining > 59)
        manager.stop()
    }

    @Test func sleepLongerThanRestRestartsFocusSession() async throws {
        let settings = IntervalSettings(workMinutes: 1, restMinutes: 2 / 60)
        let manager = IntervalManager(settings: settings, activity: StubActivity())
        manager.start()
        try await Task.sleep(for: .seconds(3))

        postSleep()
        try await Task.sleep(for: .seconds(3))
        postWake()
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.displayRemaining > 59)
        manager.stop()
    }

    @Test func repeatedSleepsWithoutWakeMeasureFromTheFirst() async throws {
        let settings = IntervalSettings(workMinutes: 1, restMinutes: 3 / 60)
        let manager = IntervalManager(settings: settings, activity: StubActivity())
        manager.start()
        try await Task.sleep(for: .seconds(3))

        // 4 s away in total, but the last fragment alone is shorter than the 3 s rest.
        postSleep()
        try await Task.sleep(for: .seconds(3))
        postSleep()
        try await Task.sleep(for: .seconds(1))
        postWake()
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.displayRemaining > 59)
        manager.stop()
    }

    @Test func shortSleepKeepsFocusSession() async throws {
        let settings = IntervalSettings(workMinutes: 1, restMinutes: 5 / 60)
        let manager = IntervalManager(settings: settings, activity: StubActivity())
        manager.start()
        try await Task.sleep(for: .seconds(3))

        postSleep()
        try await Task.sleep(for: .seconds(1))
        postWake()
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.displayRemaining < 58)
        manager.stop()
    }

    @Test func sleepLongerThanRestEndsCurrentRest() async throws {
        let settings = IntervalSettings(workMinutes: 1, restMinutes: 2 / 60, restOnAllScreens: false)
        // Input at 0 s ago freezes the countdown, standing in for ticks stopping during
        // real sleep, so only the wake handler can end this rest.
        let manager = IntervalManager(settings: settings, activity: StubActivity())
        manager.start()
        manager.restNow()
        #expect(manager.phase == .resting)

        postSleep()
        try await Task.sleep(for: .seconds(3))
        postWake()
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.phase == .working)
        manager.stop()
    }

    /// A Delay shortens only the session it applies to; coming back after a long
    /// absence starts a normal one.
    @Test func longIdleAfterSnoozeRestartsFullSession() async throws {
        let settings = IntervalSettings(workMinutes: 1, restMinutes: 2 / 60, snoozeMinutes: 10 / 60, restOnAllScreens: false)
        let activity = StubActivity()
        let manager = IntervalManager(settings: settings, activity: activity)
        manager.start()
        manager.restNow()
        manager.snooze()
        #expect(manager.displayRemaining <= 10)

        activity.secondsSinceLastInput = 3
        try await Task.sleep(for: .seconds(2))

        #expect(manager.displayRemaining > 50)
        manager.stop()
    }
}
