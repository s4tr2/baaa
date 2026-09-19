import Foundation

enum Expression: String, Codable, CaseIterable {
    case neutral, stern, happy, worried, proud
}

enum ReminderKind: String, CaseIterable, Codable, Identifiable {
    case meal, water, move, callHome, bedtime, morning, lowBattery, focusBreak

    var id: String { rawValue }

    var title: String {
        switch self {
        case .meal: return "Meals"
        case .water: return "Water"
        case .move: return "Get up & move"
        case .callHome: return "Call home"
        case .bedtime: return "Bedtime"
        case .morning: return "Good morning"
        case .lowBattery: return "Low battery"
        case .focusBreak: return "Eye break"
        }
    }

    var subtitle: String {
        switch self {
        case .meal: return "\"Khaana khaya?\" at breakfast, lunch and dinner."
        case .water: return "A glass of water, not chai."
        case .move: return "Stretch your legs. Sitting all day is not good."
        case .callHome: return "Because Mummy tells the whole colony you don't call."
        case .bedtime: return "Laptop band. So jao."
        case .morning: return "A proper start to the day."
        case .lowBattery: return "The charger is not decoration."
        case .focusBreak: return "Look away from the screen for a minute."
        }
    }

    var symbol: String {
        switch self {
        case .meal: return "fork.knife"
        case .water: return "drop.fill"
        case .move: return "figure.walk"
        case .callHome: return "phone.fill"
        case .bedtime: return "moon.zzz.fill"
        case .morning: return "sunrise.fill"
        case .lowBattery: return "battery.25percent"
        case .focusBreak: return "eye.fill"
        }
    }

    var defaultSchedule: Schedule {
        switch self {
        case .meal: return .at(times: [TimeOfDay(hour: 9, minute: 0), TimeOfDay(hour: 13, minute: 30), TimeOfDay(hour: 20, minute: 30)])
        case .water: return .every(minutes: 60)
        case .move: return .every(minutes: 90)
        case .callHome: return .weekly(weekday: 1, time: TimeOfDay(hour: 11, minute: 0))
        case .bedtime: return .at(times: [TimeOfDay(hour: 23, minute: 0)])
        case .morning: return .at(times: [TimeOfDay(hour: 8, minute: 30)])
        case .lowBattery: return .battery(threshold: 20)
        case .focusBreak: return .every(minutes: 45)
        }
    }

    /// Bedtime and morning are allowed to fire even inside quiet hours,
    /// otherwise a 23:00 bedtime nudge with 22:00 quiet hours would never show.
    var ignoresQuietHours: Bool {
        self == .bedtime || self == .morning
    }

    func expression(for tone: Tone) -> Expression {
        switch self {
        case .meal, .move, .bedtime: return tone == .strict ? .stern : .neutral
        case .water, .focusBreak: return tone == .strict ? .stern : .neutral
        case .callHome: return .happy
        case .morning: return .happy
        case .lowBattery: return .worried
        }
    }
}
