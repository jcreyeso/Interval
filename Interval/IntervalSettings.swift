import Foundation
import Observation

@Observable
final class IntervalSettings {
    static let shared = IntervalSettings()

    private enum Key {
        static let workMinutes = "workMinutes"
        static let restMinutes = "restMinutes"
        static let notificationLeadSeconds = "notificationLeadSeconds"
        static let idleThresholdSeconds = "idleThresholdSeconds"
        static let showTimerInMenuBar = "showTimerInMenuBar"
        static let restMessage = "restMessage"
        static let snoozeMinutes = "snoozeMinutes"
        static let stopOnLongIdle = "stopOnLongIdle"
        static let pauseRestOnActivity = "pauseRestOnActivity"
        static let restOnAllScreens = "restOnAllScreens"
    }

    var workMinutes: Double {
        didSet { UserDefaults.standard.set(workMinutes, forKey: Key.workMinutes) }
    }

    var restMinutes: Double {
        didSet { UserDefaults.standard.set(restMinutes, forKey: Key.restMinutes) }
    }

    var notificationLeadSeconds: Double {
        didSet { UserDefaults.standard.set(notificationLeadSeconds, forKey: Key.notificationLeadSeconds) }
    }

    var idleThresholdSeconds: Double {
        didSet { UserDefaults.standard.set(idleThresholdSeconds, forKey: Key.idleThresholdSeconds) }
    }

    var showTimerInMenuBar: Bool {
        didSet { UserDefaults.standard.set(showTimerInMenuBar, forKey: Key.showTimerInMenuBar) }
    }

    var restMessage: String {
        didSet { UserDefaults.standard.set(restMessage, forKey: Key.restMessage) }
    }

    var snoozeMinutes: Double {
        didSet { UserDefaults.standard.set(snoozeMinutes, forKey: Key.snoozeMinutes) }
    }

    var stopOnLongIdle: Bool {
        didSet { UserDefaults.standard.set(stopOnLongIdle, forKey: Key.stopOnLongIdle) }
    }

    var pauseRestOnActivity: Bool {
        didSet { UserDefaults.standard.set(pauseRestOnActivity, forKey: Key.pauseRestOnActivity) }
    }

    var restOnAllScreens: Bool {
        didSet { UserDefaults.standard.set(restOnAllScreens, forKey: Key.restOnAllScreens) }
    }

    init(
        workMinutes: Double,
        restMinutes: Double,
        notificationLeadSeconds: Double = 0,
        idleThresholdSeconds: Double = 30,
        showTimerInMenuBar: Bool = false,
        restMessage: String = "",
        snoozeMinutes: Double = 5,
        stopOnLongIdle: Bool = true,
        pauseRestOnActivity: Bool = true,
        restOnAllScreens: Bool = true
    ) {
        self.workMinutes = workMinutes
        self.restMinutes = restMinutes
        self.notificationLeadSeconds = notificationLeadSeconds
        self.idleThresholdSeconds = idleThresholdSeconds
        self.showTimerInMenuBar = showTimerInMenuBar
        self.restMessage = restMessage
        self.snoozeMinutes = snoozeMinutes
        self.stopOnLongIdle = stopOnLongIdle
        self.pauseRestOnActivity = pauseRestOnActivity
        self.restOnAllScreens = restOnAllScreens
    }

    private init() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            Key.workMinutes: 25.0,
            Key.restMinutes: 5.0,
            Key.notificationLeadSeconds: 10.0,
            Key.idleThresholdSeconds: 30.0,
            Key.showTimerInMenuBar: true,
            Key.restMessage: "Time to rest.\nStand up, stretch, breathe.",
            Key.snoozeMinutes: 5.0,
            Key.stopOnLongIdle: true,
            Key.pauseRestOnActivity: true,
            Key.restOnAllScreens: true
        ])
        self.workMinutes = defaults.double(forKey: Key.workMinutes)
        self.restMinutes = defaults.double(forKey: Key.restMinutes)
        self.notificationLeadSeconds = defaults.double(forKey: Key.notificationLeadSeconds)
        self.idleThresholdSeconds = defaults.double(forKey: Key.idleThresholdSeconds)
        self.showTimerInMenuBar = defaults.bool(forKey: Key.showTimerInMenuBar)
        self.restMessage = defaults.string(forKey: Key.restMessage) ?? ""
        self.snoozeMinutes = defaults.double(forKey: Key.snoozeMinutes)
        self.stopOnLongIdle = defaults.bool(forKey: Key.stopOnLongIdle)
        self.pauseRestOnActivity = defaults.bool(forKey: Key.pauseRestOnActivity)
        self.restOnAllScreens = defaults.bool(forKey: Key.restOnAllScreens)
    }
}
