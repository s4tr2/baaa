import Foundation

enum Language: String, CaseIterable, Codable, Identifiable {
    case english, hinglish, hindi, tamil, telugu, malayalam, kannada, marathi, gujarati, bengali, punjabi

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .hinglish: return "Hinglish"
        case .hindi: return "हिन्दी"
        case .tamil: return "தமிழ்"
        case .telugu: return "తెలుగు"
        case .malayalam: return "മലയാളം"
        case .kannada: return "ಕನ್ನಡ"
        case .marathi: return "मराठी"
        case .gujarati: return "ગુજરાતી"
        case .bengali: return "বাংলা"
        case .punjabi: return "ਪੰਜਾਬੀ"
        }
    }

    /// What the app calls him by default in this language.
    var defaultPapaName: String {
        switch self {
        case .english: return "Dad"
        case .hinglish: return "Papa"
        case .hindi: return "पापा"
        case .tamil: return "அப்பா"
        case .telugu: return "నాన్న"
        case .malayalam: return "അച്ഛൻ"
        case .kannada: return "ಅಪ್ಪ"
        case .marathi: return "बाबा"
        case .gujarati: return "પપ્પા"
        case .bengali: return "বাবা"
        case .punjabi: return "ਪਾਪਾ ਜੀ"
        }
    }

    /// What he calls you by default. Substituted for {name} in messages.
    var defaultChildName: String {
        switch self {
        case .english, .hinglish: return "beta"
        case .hindi: return "बेटा"
        case .tamil: return "கண்ணா"
        case .telugu: return "నాన్నా"
        case .malayalam: return "കുട്ടീ"
        case .kannada: return "ಪುಟ್ಟಾ"
        case .marathi: return "बाळा"
        case .gujarati: return "બેટા"
        case .bengali: return "বাবু"
        case .punjabi: return "ਪੁੱਤ"
        }
    }
}

enum Tone: String, CaseIterable, Codable, Identifiable {
    case strict, soft, funny

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .strict: return "Strict Papa"
        case .soft: return "Soft Papa"
        case .funny: return "Filmy Papa"
        }
    }

    var blurb: String {
        switch self {
        case .strict: return "No 'later'. No excuses. He means well, loudly."
        case .soft: return "Gentle check-ins, the way he talks when Mummy is listening."
        case .funny: return "One-liners, old-days stories, and unsolicited life tips."
        }
    }
}
