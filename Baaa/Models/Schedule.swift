import Foundation

struct TimeOfDay: Codable, Hashable {
    var hour: Int
    var minute: Int

    init(hour: Int, minute: Int = 0) {
        self.hour = hour
        self.minute = minute
    }

    init(date: Date) {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        hour = comps.hour ?? 0
        minute = comps.minute ?? 0
    }

    var minutesSinceMidnight: Int { hour * 60 + minute }

    func date(on day: Date = Date()) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    var slotKey: String { String(format: "%02d:%02d", hour, minute) }

    var formatted: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date())
    }
}

enum Schedule: Codable, Hashable {
    /// Fires every N minutes of active use.
    case every(minutes: Int)
    /// Fires at fixed times each day.
    case at(times: [TimeOfDay])
    /// Fires once a week. `weekday` uses Calendar numbering (1 = Sunday).
    case weekly(weekday: Int, time: TimeOfDay)
    /// Fires when running on battery at or below the threshold percentage.
    case battery(threshold: Int)
    /// Fires when plugged in and charged to at least the threshold percentage.
    case charged(threshold: Int)
    /// Fires when the Trash holds at least this many items.
    case trash(minItems: Int)

    var summary: String {
        switch self {
        case .every(let m):
            if m % 60 == 0 { return m == 60 ? "Every hour" : "Every \(m / 60) hours" }
            return "Every \(m) min"
        case .at(let times):
            return times.sorted { $0.minutesSinceMidnight < $1.minutesSinceMidnight }
                .map(\.formatted).joined(separator: ", ")
        case .weekly(let wd, let t):
            let names = Calendar.current.weekdaySymbols
            let name = (1...7).contains(wd) ? names[wd - 1] : "Sunday"
            return "\(name)s at \(t.formatted)"
        case .battery(let th):
            return "Below \(th)%"
        case .charged(let th):
            return th >= 100 ? "Plugged in, fully charged" : "Plugged in above \(th)%"
        case .trash(let n):
            return n <= 1 ? "Anything in the Trash" : "\(n) or more items in the Trash"
        }
    }
}
