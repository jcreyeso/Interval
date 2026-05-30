import Foundation
import SwiftData

@Model
final class DayStat {
    @Attribute(.unique) var dayKey: String
    var date: Date
    var workSeconds: Double
    var restSeconds: Double
    var restCount: Int

    init(
        dayKey: String,
        date: Date,
        workSeconds: Double = 0,
        restSeconds: Double = 0,
        restCount: Int = 0
    ) {
        self.dayKey = dayKey
        self.date = date
        self.workSeconds = workSeconds
        self.restSeconds = restSeconds
        self.restCount = restCount
    }
}

enum DayKey {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func key(for date: Date) -> String { formatter.string(from: date) }

    static func startOfDay(for date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    static func date(forKey key: String) -> Date {
        formatter.date(from: key) ?? Calendar.current.startOfDay(for: Date())
    }
}
