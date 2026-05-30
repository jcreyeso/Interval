import Foundation
import SwiftData

@MainActor
final class StatsRecorder {
    private let container: ModelContainer
    private let context: ModelContext

    // In-memory deltas accumulated between flushes. We avoid hitting SwiftData
    // every tick — writes happen on phase transitions, day rollover, app
    // termination, or when the Statistics window opens.
    private var pendingWork: TimeInterval = 0
    private var pendingRest: TimeInterval = 0
    private var pendingRestCount: Int = 0

    // The day the pending deltas belong to. If the wall clock crosses midnight
    // mid-session we flush to the old day before switching.
    private var currentDayKey: String

    init(container: ModelContainer) {
        self.container = container
        self.context = ModelContext(container)
        self.currentDayKey = DayKey.key(for: Date())
    }

    // MARK: - Recording (called from IntervalManager)

    func addWork(_ seconds: TimeInterval) {
        guard seconds > 0 else { return }
        rolloverIfNeeded()
        pendingWork += seconds
    }

    func addRest(_ seconds: TimeInterval) {
        guard seconds > 0 else { return }
        rolloverIfNeeded()
        pendingRest += seconds
    }

    func recordRestStarted() {
        rolloverIfNeeded()
        pendingRestCount += 1
        flush()
    }

    func flush() {
        rolloverIfNeeded()
        guard pendingWork > 0 || pendingRest > 0 || pendingRestCount > 0 else { return }
        let day = fetchOrCreate(dayKey: currentDayKey)
        day.workSeconds += pendingWork
        day.restSeconds += pendingRest
        day.restCount += pendingRestCount
        pendingWork = 0
        pendingRest = 0
        pendingRestCount = 0
        try? context.save()
    }

    // MARK: - Reads (for the Statistics view)

    func snapshot(for date: Date) -> DayStat? {
        let key = DayKey.key(for: date)
        // If asking about the in-memory day, flush pending so the read is accurate.
        if key == currentDayKey { flush() }
        return fetch(dayKey: key)
    }

    func allTimeTotals() -> (work: Double, rest: Double, restCount: Int) {
        flush()
        let descriptor = FetchDescriptor<DayStat>()
        let days = (try? context.fetch(descriptor)) ?? []
        return days.reduce(into: (0.0, 0.0, 0)) { acc, d in
            acc.0 += d.workSeconds
            acc.1 += d.restSeconds
            acc.2 += d.restCount
        }
    }

    // MARK: - Internals

    private func rolloverIfNeeded() {
        let nowKey = DayKey.key(for: Date())
        guard nowKey != currentDayKey else { return }
        // Flush whatever was pending to the *previous* day before switching.
        if pendingWork > 0 || pendingRest > 0 || pendingRestCount > 0 {
            let day = fetchOrCreate(dayKey: currentDayKey)
            day.workSeconds += pendingWork
            day.restSeconds += pendingRest
            day.restCount += pendingRestCount
            pendingWork = 0
            pendingRest = 0
            pendingRestCount = 0
            try? context.save()
        }
        currentDayKey = nowKey
    }

    private func fetch(dayKey: String) -> DayStat? {
        var descriptor = FetchDescriptor<DayStat>(
            predicate: #Predicate { $0.dayKey == dayKey }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func fetchOrCreate(dayKey: String) -> DayStat {
        if let existing = fetch(dayKey: dayKey) { return existing }
        let stat = DayStat(dayKey: dayKey, date: DayKey.date(forKey: dayKey))
        context.insert(stat)
        return stat
    }
}
