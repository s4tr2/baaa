import Foundation

/// What Baaa Pro unlocks. Free keeps the essentials: meals, water, movement,
/// bedtime, good morning, every language, Soft Papa and the bundled 3D Papa.
enum ProFeature: CaseIterable {
    case customMessages, customReminders, tones, advancedReminders, customPicture

    var title: String {
        switch self {
        case .customMessages: return "Custom instructions"
        case .customReminders: return "Your own reminders"
        case .tones: return "Strict Papa & Filmy Papa"
        case .advancedReminders: return "Call home, low battery, eye breaks"
        case .customPicture: return "Your own picture of Papa"
        }
    }

    var detail: String {
        switch self {
        case .customMessages: return "Write exactly what he says, in your words, with an English line if you like."
        case .customReminders: return "Medicines, watering the tulsi, standing up for the delivery guy."
        case .tones: return "Two more voices. One shouts, one quotes old films."
        case .advancedReminders: return "The reminders that need a bit more of him."
        case .customPicture: return "Drop in any PNG and he becomes that person."
        }
    }

    var symbol: String {
        switch self {
        case .customMessages: return "text.bubble.fill"
        case .customReminders: return "star.fill"
        case .tones: return "waveform"
        case .advancedReminders: return "bell.badge.fill"
        case .customPicture: return "photo.fill"
        }
    }
}

extension ReminderKind {
    var isPro: Bool {
        switch self {
        case .callHome, .lowBattery, .focusBreak: return true
        default: return false
        }
    }
}

extension Tone {
    var isPro: Bool { self != .soft }
}
