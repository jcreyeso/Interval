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
}
