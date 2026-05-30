import SwiftUI
import SwiftData

struct StatisticsView: View {
    let manager: IntervalManager

    @Environment(\.modelContext) private var context
    @Query(sort: \DayStat.date, order: .reverse) private var allDays: [DayStat]

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.title.weight(.semibold))

            HStack(alignment: .top, spacing: 24) {
                DatePicker(
                    "Day",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .frame(maxWidth: 320)

                daySection
                    .frame(minWidth: 240, alignment: .leading)
            }
        }
        .padding(24)
        .frame(minWidth: 640, minHeight: 460)
        .onAppear { manager.flushStats() }
    }

    private var selectedDay: DayStat? {
        let key = DayKey.key(for: selectedDate)
        return allDays.first { $0.dayKey == key }
    }

    @ViewBuilder
    private var daySection: some View {
        let day = selectedDay
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedDate, format: .dateTime.weekday(.wide).month(.wide).day().year())
                .font(.headline)

            statRow(label: "Work time", value: formatDuration(day?.workSeconds ?? 0), icon: "brain.head.profile")
            statRow(label: "Rest time", value: formatDuration(day?.restSeconds ?? 0), icon: "leaf.fill")
            statRow(label: "Rest intervals", value: "\(day?.restCount ?? 0)", icon: "number.circle.fill")
        }
    }

    private func statRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(.secondary)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .font(.title3.weight(.medium))
                .monospacedDigit()
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%dh %02dm %02ds", h, m, s) }
        if m > 0 { return String(format: "%dm %02ds", m, s) }
        return "\(s)s"
    }
}
