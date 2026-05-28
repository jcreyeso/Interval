import Testing
import Foundation
@testable import Interval

@MainActor
private final class StubActivity: ActivityMonitoring {
    var isScreenLocked = false
    var secondsSinceLastInput: TimeInterval = 0
}

@MainActor
struct IntervalTests {

    /// Verifies that when the rest interval expires the work counter restarts
    /// automatically — no user action required — even when the user was idle
    /// for the entire rest period (the realistic case).
    @Test func restCompletionRestartsWorkCounter() async throws {
        // 2-second work phase, 2-second rest phase
        let settings = IntervalSettings(workMinutes: 2 / 60, restMinutes: 2 / 60)
        let activity = StubActivity()
        let manager = IntervalManager(settings: settings, activity: activity)

        manager.start()

        // Work phase takes ~2 s; wait 3 s with margin
        try await Task.sleep(for: .seconds(3))
        #expect(manager.phase == .resting,
                "Manager should enter rest phase automatically when work interval ends")

        // Simulate the user being idle the whole rest period — this is the
        // exact condition that previously caused stop() to fire on the first
        // tick after rest, sending phase back to .idle.
        activity.secondsSinceLastInput = settings.restMinutes * 60

        // Rest phase takes ~2 s; wait 3 s with margin
        try await Task.sleep(for: .seconds(3))
        #expect(manager.phase != .idle,
                "Manager must not stop itself after rest ends — no user action required")
        #expect(manager.phase == .working || manager.phase == .resting,
                "Manager should be working (or still resting) after rest ends")

        manager.stop()
    }
}
