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
        static let restMessage = "restMessage"
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

    var restMessage: String {
        didSet { UserDefaults.standard.set(restMessage, forKey: Key.restMessage) }
    }

    private init() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            Key.workMinutes: 25.0,
            Key.restMinutes: 5.0,
            Key.notificationLeadSeconds: 10.0,
            Key.idleThresholdSeconds: 30.0,
            Key.restMessage: "Time to rest.\nStand up, stretch, breathe."
        ])
        self.workMinutes = defaults.double(forKey: Key.workMinutes)
        self.restMinutes = defaults.double(forKey: Key.restMinutes)
        self.notificationLeadSeconds = defaults.double(forKey: Key.notificationLeadSeconds)
        self.idleThresholdSeconds = defaults.double(forKey: Key.idleThresholdSeconds)
        self.restMessage = defaults.string(forKey: Key.restMessage) ?? ""
    }
}
