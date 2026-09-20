import Foundation

/// One thing Papa wants to say, ready to display.
struct Nudge: Identifiable, Equatable {
    let id = UUID()
    /// Stable key for the reminder that produced this (kind raw value or custom UUID).
    let sourceKey: String
    let kind: ReminderKind?
    let speaker: String
    let message: String
    /// Optional English gloss shown in grey under the message.
    let subtitle: String?
    let expression: Expression
    let symbol: String
    /// The Chappal Treatment: Strict Papa has been ignored twice and the chappal flies out of the notch.
    let chappal: Bool

    init(sourceKey: String, kind: ReminderKind?, speaker: String, message: String,
         subtitle: String? = nil, expression: Expression, symbol: String, chappal: Bool = false) {
        self.sourceKey = sourceKey
        self.kind = kind
        self.speaker = speaker
        self.message = message
        self.subtitle = subtitle
        self.expression = expression
        self.symbol = symbol
        self.chappal = chappal
    }

    /// The same nudge, escalated: angry face, chappal out, and the chappal line on top
    /// with the original instruction underneath so you still know what he wants.
    func escalated(with line: Line, settings: AppSettings) -> Nudge {
        Nudge(sourceKey: sourceKey, kind: kind, speaker: speaker,
              message: line.text.substituting(settings: settings),
              subtitle: message, expression: .angry, symbol: symbol, chappal: true)
    }

    static func welcome(settings: AppSettings) -> Nudge {
        let line = MessageLibrary.pack(settings.language).welcome
        return Nudge(
            sourceKey: "welcome",
            kind: nil,
            speaker: settings.resolvedPapaName,
            message: line.text.substituting(settings: settings),
            subtitle: line.english?.substituting(settings: settings),
            expression: .proud,
            symbol: "hand.wave.fill"
        )
    }
}

extension String {
    func substituting(settings: AppSettings) -> String {
        self.replacingOccurrences(of: "{name}", with: settings.resolvedChildName)
            .replacingOccurrences(of: "{papa}", with: settings.resolvedPapaName)
    }
}

extension Line {
    /// Custom messages may carry their own gloss after " // ", e.g. "Dawai li? // Took your medicine?"
    static func parseCustom(_ raw: String) -> Line? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let parts = trimmed.components(separatedBy: " // ")
        if parts.count >= 2 {
            let gloss = parts.dropFirst().joined(separator: " // ").trimmingCharacters(in: .whitespaces)
            return Line(parts[0].trimmingCharacters(in: .whitespaces), gloss.isEmpty ? nil : gloss)
        }
        return Line(trimmed)
    }
}
