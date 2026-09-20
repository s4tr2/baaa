import Foundation

struct QuietHours: Codable, Hashable {
    var enabled: Bool = true
    var start: TimeOfDay = TimeOfDay(hour: 22, minute: 0)
    var end: TimeOfDay = TimeOfDay(hour: 8, minute: 0)

    func contains(_ date: Date) -> Bool {
        guard enabled else { return false }
        let now = TimeOfDay(date: date).minutesSinceMidnight
        let s = start.minutesSinceMidnight
        let e = end.minutesSinceMidnight
        if s == e { return false }
        if s < e { return now >= s && now < e }
        // Overnight window, e.g. 22:00 -> 08:00
        return now >= s || now < e
    }
}

struct ReminderConfig: Codable, Identifiable, Hashable {
    var kind: ReminderKind
    var enabled: Bool
    var schedule: Schedule
    var customMessages: [String]
    var useOnlyCustom: Bool

    var id: ReminderKind { kind }

    static func `default`(for kind: ReminderKind) -> ReminderConfig {
        ReminderConfig(kind: kind, enabled: true, schedule: kind.defaultSchedule, customMessages: [], useOnlyCustom: false)
    }
}

struct CustomReminder: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var title: String = "My reminder"
    var enabled: Bool = true
    var schedule: Schedule = .every(minutes: 120)
    var messages: [String] = [""]
    var expression: Expression = .neutral
}

enum NotchPlacement: String, Codable, CaseIterable, Identifiable {
    case auto, notch, floating
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .auto: return "Automatic"
        case .notch: return "Always from the notch"
        case .floating: return "Floating below the menu bar"
        }
    }
}

struct AppSettings: Codable {
    var language: Language = .hinglish
    var tone: Tone = .soft
    /// Empty means "use the language default".
    var papaName: String = ""
    /// Empty means "use the language default".
    var childName: String = ""
    var quietHours = QuietHours()
    var dailyLimit: Int = 12
    var displaySeconds: Double = 9
    var soundEnabled: Bool = true
    /// The Chappal Treatment. Strict Papa only: ignore him twice in a row and the chappal flies out of the notch.
    var chappalTreatment: Bool = true
    var placement: NotchPlacement = .auto
    var reminders: [ReminderConfig] = ReminderKind.allCases.map(ReminderConfig.default(for:))
    var customReminders: [CustomReminder] = []
    var avatar = AvatarConfig()
    var hasOnboarded: Bool = false

    var resolvedPapaName: String {
        papaName.trimmingCharacters(in: .whitespaces).isEmpty ? language.defaultPapaName : papaName
    }

    var resolvedChildName: String {
        childName.trimmingCharacters(in: .whitespaces).isEmpty ? language.defaultChildName : childName
    }

    func reminder(_ kind: ReminderKind) -> ReminderConfig {
        reminders.first { $0.kind == kind } ?? .default(for: kind)
    }

    init() {}

    // Tolerant decoding so settings survive new fields between versions.
    enum CodingKeys: String, CodingKey {
        case language, tone, papaName, childName, quietHours, dailyLimit, displaySeconds, soundEnabled,
             chappalTreatment, placement, reminders, customReminders, avatar, hasOnboarded
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = AppSettings()
        language = try c.decodeIfPresent(Language.self, forKey: .language) ?? d.language
        tone = try c.decodeIfPresent(Tone.self, forKey: .tone) ?? d.tone
        papaName = try c.decodeIfPresent(String.self, forKey: .papaName) ?? d.papaName
        childName = try c.decodeIfPresent(String.self, forKey: .childName) ?? d.childName
        quietHours = try c.decodeIfPresent(QuietHours.self, forKey: .quietHours) ?? d.quietHours
        dailyLimit = try c.decodeIfPresent(Int.self, forKey: .dailyLimit) ?? d.dailyLimit
        displaySeconds = try c.decodeIfPresent(Double.self, forKey: .displaySeconds) ?? d.displaySeconds
        soundEnabled = try c.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? d.soundEnabled
        chappalTreatment = try c.decodeIfPresent(Bool.self, forKey: .chappalTreatment) ?? d.chappalTreatment
        placement = try c.decodeIfPresent(NotchPlacement.self, forKey: .placement) ?? d.placement
        var decodedReminders = try c.decodeIfPresent([ReminderConfig].self, forKey: .reminders) ?? []
        for kind in ReminderKind.allCases where !decodedReminders.contains(where: { $0.kind == kind }) {
            decodedReminders.append(.default(for: kind))
        }
        reminders = decodedReminders
        customReminders = try c.decodeIfPresent([CustomReminder].self, forKey: .customReminders) ?? d.customReminders
        avatar = try c.decodeIfPresent(AvatarConfig.self, forKey: .avatar) ?? d.avatar
        hasOnboarded = try c.decodeIfPresent(Bool.self, forKey: .hasOnboarded) ?? d.hasOnboarded
    }
}
