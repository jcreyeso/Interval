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
        case userIdle, screenLocked, userActive
    }

    private(set) var phase: Phase = .idle
    private(set) var displayRemaining: TimeInterval = 0
    private(set) var isPaused: Bool = false
    private(set) var pauseReason: PauseReason?

    private let settings: IntervalSettings
    private let activity: any ActivityMonitoring
    private let restWindow = RestWindowController()
    private var tickTimer: Timer?

    // Work-phase accumulation
    private var workTargetSeconds: TimeInterval = 0
    private var workAccumulatedSeconds: TimeInterval = 0
    private var lastTickAt: Date?
    private var advanceNotificationSent = false

    // Rest-phase accumulation
    private var restTargetSeconds: TimeInterval = 0
    private var restAccumulatedSeconds: TimeInterval = 0

    // True for the single tick that begins the work phase after a natural rest completion.
    // Prevents the idle-away check from immediately stopping a timer the user never touched.
    private var suppressIdleResetAfterRest = false

    private let advanceNotificationId = "interval.advance"

    // Cap per-tick elapsed so a system sleep / screen lock gap does not
    // dump minutes of phantom work time into the accumulator on resume.
    private let maxElapsedPerTick: TimeInterval = 2.0

    // Rest pauses while the user is still actively using the keyboard/mouse.
    // If their last input was less than this many seconds ago, treat them as
    // "still interacting" and freeze the rest countdown.
    private let restInteractionThreshold: TimeInterval = 2.0

    init(settings: IntervalSettings? = nil, activity: (any ActivityMonitoring)? = nil) {
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
        restTargetSeconds = 0
        restAccumulatedSeconds = 0
        lastTickAt = nil
        advanceNotificationSent = false
        suppressIdleResetAfterRest = false
        cancelAdvanceNotification()
        restWindow.dismiss()
    }

    func skipRest() {
        guard phase == .resting else { return }
        restWindow.dismiss()
        beginWorking()
    }

    func snooze() {
        guard phase == .resting else { return }
        cancelAdvanceNotification()
        beginWorking(targetSeconds: max(1, settings.snoozeMinutes * 60))
    }

    func restNow() {
        guard phase == .working else { return }
        cancelAdvanceNotification()
        beginResting(manual: true)
    }

    // MARK: - Phase transitions

    private func beginWorking(targetSeconds: TimeInterval? = nil) {
        phase = .working
        workTargetSeconds = targetSeconds ?? max(1, settings.workMinutes * 60)
        workAccumulatedSeconds = 0
        advanceNotificationSent = false
        lastTickAt = Date()
        displayRemaining = workTargetSeconds
        isPaused = false
        pauseReason = nil
        restWindow.dismiss()
        startTicking()
    }

    private func beginResting(manual: Bool = false) {
        phase = .resting
        let duration = max(1, settings.restMinutes * 60)
        restTargetSeconds = duration
        restAccumulatedSeconds = 0
        displayRemaining = duration
        isPaused = false
        pauseReason = nil
        lastTickAt = Date()
        cancelAdvanceNotification()

        restWindow.present(
            manager: self,
            message: settings.restMessage,
            snoozeMinutes: settings.snoozeMinutes,
            allowSkip: !manual,
            onSkip: { [weak self] in self?.skipRest() },
            onSnooze: { [weak self] in self?.snooze() }
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
            tickResting(elapsed: elapsed)
        }
    }

    private func tickWorking(elapsed: TimeInterval) {
        let locked = activity.isScreenLocked
        let idleSeconds = activity.secondsSinceLastInput
        let restDurationSeconds = settings.restMinutes * 60

        // User was away longer than a full rest break — reset the work timer.
        // Skip on the first tick after natural rest completion: the user was
        // intentionally idle during rest, so idleSeconds ≈ restDurationSeconds.
        // Also skip entirely if the user has disabled long-idle auto-stop.
        if suppressIdleResetAfterRest {
            suppressIdleResetAfterRest = false
        } else if settings.stopOnLongIdle, !locked, idleSeconds >= restDurationSeconds {
            stop()
            return
        }

        let userIdle = idleSeconds > settings.idleThresholdSeconds

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

    private func tickResting(elapsed: TimeInterval) {
        // If the user is still touching the keyboard/mouse, freeze the rest
        // countdown until they stop — but only when the user has opted in.
        let interacting = settings.pauseRestOnActivity
            && activity.secondsSinceLastInput < restInteractionThreshold

        if interacting {
            isPaused = true
            pauseReason = .userActive
        } else {
            isPaused = false
            pauseReason = nil
            restAccumulatedSeconds += elapsed
        }

        let remaining = max(0, restTargetSeconds - restAccumulatedSeconds)
        displayRemaining = remaining

        if remaining <= 0 {
            restWindow.dismiss()
            suppressIdleResetAfterRest = true
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
