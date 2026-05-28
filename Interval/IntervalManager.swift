import Foundation
import Observation
import UserNotifications
import AppKit

@MainActor
@Observable
final class IntervalManager {
    enum Phase: String {
        case idle, working, resting
    }

    enum PauseReason {
        case userIdle, screenLocked
    }

    private(set) var phase: Phase = .idle
    private(set) var displayRemaining: TimeInterval = 0
    private(set) var isPaused: Bool = false
    private(set) var pauseReason: PauseReason?

    private let settings: IntervalSettings
    private let activity: ActivityMonitor
    private let restWindow = RestWindowController()
    private var tickTimer: Timer?

    // Work-phase accumulation
    private var workTargetSeconds: TimeInterval = 0
    private var workAccumulatedSeconds: TimeInterval = 0
    private var lastTickAt: Date?
    private var advanceNotificationSent = false

    // Rest-phase wall-clock end
    private var restEndsAt: Date?

    private let advanceNotificationId = "interval.advance"

    // Cap per-tick elapsed so a system sleep / screen lock gap does not
    // dump minutes of phantom work time into the accumulator on resume.
    private let maxElapsedPerTick: TimeInterval = 2.0

    init(settings: IntervalSettings? = nil, activity: ActivityMonitor? = nil) {
        self.settings = settings ?? .shared
        self.activity = activity ?? ActivityMonitor()
        Task { await requestNotificationAuthorization() }
    }

    func start() { beginWorking() }

    func stop() {
        tickTimer?.invalidate()
        tickTimer = nil
        phase = .idle
        displayRemaining = 0
        isPaused = false
        pauseReason = nil
        workTargetSeconds = 0
        workAccumulatedSeconds = 0
        restEndsAt = nil
        lastTickAt = nil
        advanceNotificationSent = false
        cancelAdvanceNotification()
        restWindow.dismiss()
    }

    func skipRest() {
        guard phase == .resting else { return }
        restWindow.dismiss()
        beginWorking()
    }

    func restNow() {
        guard phase == .working else { return }
        cancelAdvanceNotification()
        beginResting()
    }

    // MARK: - Phase transitions

    private func beginWorking() {
        phase = .working
        workTargetSeconds = max(1, settings.workMinutes * 60)
        workAccumulatedSeconds = 0
        advanceNotificationSent = false
        lastTickAt = Date()
        displayRemaining = workTargetSeconds
        isPaused = false
        pauseReason = nil
        restWindow.dismiss()
        startTicking()
    }

    private func beginResting() {
        phase = .resting
        let duration = max(1, settings.restMinutes * 60)
        let end = Date().addingTimeInterval(duration)
        restEndsAt = end
        displayRemaining = duration
        isPaused = false
        pauseReason = nil
        lastTickAt = Date()
        cancelAdvanceNotification()

        restWindow.present(
            message: settings.restMessage,
            endsAt: end,
            onSkip: { [weak self] in self?.skipRest() }
        )

        startTicking()
    }

    // MARK: - Tick loop

    private func startTicking() {
        tickTimer?.invalidate()
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        tickTimer = timer
        tick()
    }

    private func tick() {
        let now = Date()
        let raw = now.timeIntervalSince(lastTickAt ?? now)
        let elapsed = min(maxElapsedPerTick, max(0, raw))
        lastTickAt = now

        switch phase {
        case .idle:
            return
        case .working:
            tickWorking(elapsed: elapsed)
        case .resting:
            tickResting(now: now)
        }
    }

    private func tickWorking(elapsed: TimeInterval) {
        let locked = activity.isScreenLocked
        let userIdle = activity.secondsSinceLastInput > settings.idleThresholdSeconds

        if locked {
            isPaused = true
            pauseReason = .screenLocked
        } else if userIdle {
            isPaused = true
            pauseReason = .userIdle
        } else {
            isPaused = false
            pauseReason = nil
            workAccumulatedSeconds += elapsed
        }

        let remaining = max(0, workTargetSeconds - workAccumulatedSeconds)
        displayRemaining = remaining

        if !advanceNotificationSent,
           !isPaused,
           remaining > 0,
           remaining <= settings.notificationLeadSeconds {
            postAdvanceNotification(secondsAhead: max(1, Int(remaining.rounded())))
            advanceNotificationSent = true
        }

        if remaining <= 0 {
            beginResting()
        }
    }

    private func tickResting(now: Date) {
        guard let end = restEndsAt else { return }
        let remaining = max(0, end.timeIntervalSince(now))
        displayRemaining = remaining
        if remaining <= 0 {
            restWindow.dismiss()
            beginWorking()
        }
    }

    // MARK: - Notifications

    private func requestNotificationAuthorization() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])
    }

    private func postAdvanceNotification(secondsAhead: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Rest break coming up"
        content.body = "Your rest starts in \(secondsAhead) second\(secondsAhead == 1 ? "" : "s")."
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: advanceNotificationId,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func cancelAdvanceNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [advanceNotificationId])
        center.removeDeliveredNotifications(withIdentifiers: [advanceNotificationId])
    }
}
