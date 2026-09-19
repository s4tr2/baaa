import AppKit
import Combine

/// Decides *when* Papa speaks. The notch decides *how*.
@MainActor
final class ReminderEngine: ObservableObject {
    @Published private(set) var pausedUntil: Date?
    @Published private(set) var shownToday = 0

    private let store: SettingsStore
    private let notch: NotchController
    private var timer: Timer?
    private let startedAt = Date()

    private var lastFired: [String: Date] = [:]
    private var firedSlots: Set<String> = []
    private var dayKey = ""
    private var lastMessage: [String: String] = [:]
    private var snoozed: (nudge: Nudge, until: Date)?

    private let tickInterval: TimeInterval = 20
    private let slotWindowMinutes = 20
    private let idleThreshold: TimeInterval = 5 * 60

    init(store: SettingsStore, notch: NotchController) {
        self.store = store
        self.notch = notch
        notch.onSnooze = { [weak self] nudge in self?.snooze(nudge, minutes: 10) }
        notch.onDone = { [weak self] nudge in self?.markDone(nudge) }
    }

    var isPaused: Bool {
        if let until = pausedUntil { return until > Date() }
        return false
    }

    func start() {
        rolloverDayIfNeeded()
        timer?.invalidate()
        let t = Timer(timeInterval: tickInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        t.tolerance = 5
        RunLoop.main.add(t, forMode: .common)
        timer = t

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            // Interval reminders shouldn't fire the instant the lid opens.
            Task { @MainActor in self?.resetIntervalBaselines() }
        }
    }

    // MARK: - Controls

    func pause(for interval: TimeInterval) {
        pausedUntil = Date().addingTimeInterval(interval)
        notch.hide()
    }

    func pauseUntilTomorrow() {
        let cal = Calendar.current
        if let tomorrow = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date())) {
            let wake = store.settings.quietHours.end.date(on: tomorrow)
            pausedUntil = wake
        }
        notch.hide()
    }

    func resume() {
        pausedUntil = nil
    }

    /// Forces a nudge right now. Used by the menu bar and Settings previews.
    func nudgeNow(kind: ReminderKind? = nil) {
        let settings = store.settings
        let pro = LicenseManager.shared.isPro
        let enabledKinds = settings.reminders.filter { $0.enabled && (pro || !$0.kind.isPro) }.map(\.kind)
        let chosen = kind ?? enabledKinds.randomElement() ?? .meal
        let config = settings.reminder(chosen)
        let nudge = makeNudge(for: config, settings: settings)
        notch.show(nudge)
    }

    func preview(customReminder: CustomReminder) {
        let settings = store.settings
        notch.show(makeNudge(for: customReminder, settings: settings))
    }

    func preview(message: String, expression: Expression = .neutral) {
        let settings = store.settings
        notch.show(Nudge(sourceKey: "preview", kind: nil, speaker: settings.resolvedPapaName,
                         message: message.substituting(settings: settings), expression: expression, symbol: "text.bubble.fill"))
    }

    func snooze(_ nudge: Nudge, minutes: Int) {
        snoozed = (nudge, Date().addingTimeInterval(TimeInterval(minutes * 60)))
    }

    func markDone(_ nudge: Nudge) {
        if snoozed?.nudge.sourceKey == nudge.sourceKey { snoozed = nil }
    }

    // MARK: - Tick

    private func tick() {
        rolloverDayIfNeeded()
        let now = Date()
        let settings = store.settings

        if let until = pausedUntil, until <= now { pausedUntil = nil }
        guard !isPaused else { return }
        guard !notch.isVisible else { return }

        if let s = snoozed, s.until <= now {
            if !settings.quietHours.contains(now) {
                snoozed = nil
                present(s.nudge, key: s.nudge.sourceKey)
            }
            return
        }

        guard IdleMonitor.secondsIdle < idleThreshold else { return }
        guard shownToday < settings.dailyLimit else { return }

        let inQuiet = settings.quietHours.contains(now)

        // Built-in reminders: time-based first, then intervals, then battery.
        let pro = LicenseManager.shared.isPro
        let ordered = settings.reminders.filter { $0.enabled && (pro || !$0.kind.isPro) }.sorted { a, b in
            priority(a.schedule) < priority(b.schedule)
        }
        for config in ordered {
            if inQuiet && !config.kind.ignoresQuietHours { continue }
            if let slot = dueSlot(for: config.schedule, key: config.kind.rawValue, now: now) {
                let nudge = makeNudge(for: config, settings: settings)
                present(nudge, key: config.kind.rawValue, slot: slot)
                return
            }
        }

        if !inQuiet && pro {
            for custom in settings.customReminders where custom.enabled {
                let key = custom.id.uuidString
                if let slot = dueSlot(for: custom.schedule, key: key, now: now) {
                    present(makeNudge(for: custom, settings: settings), key: key, slot: slot)
                    return
                }
            }
        }
    }

    private func priority(_ s: Schedule) -> Int {
        switch s {
        case .at, .weekly: return 0
        case .battery: return 1
        case .every: return 2
        }
    }

    /// Returns a slot identifier if the schedule is due now, else nil.
    private func dueSlot(for schedule: Schedule, key: String, now: Date) -> String? {
        switch schedule {
        case .every(let minutes):
            let base = lastFired[key] ?? startedAt
            return now.timeIntervalSince(base) >= TimeInterval(max(5, minutes) * 60) ? "interval" : nil

        case .at(let times):
            let nowMin = TimeOfDay(date: now).minutesSinceMidnight
            for t in times {
                let start = t.minutesSinceMidnight
                let slot = "\(key)|\(dayKey)|\(t.slotKey)"
                if nowMin >= start && nowMin < start + slotWindowMinutes && !firedSlots.contains(slot) {
                    return slot
                }
            }
            return nil

        case .weekly(let weekday, let time):
            guard Calendar.current.component(.weekday, from: now) == weekday else { return nil }
            let nowMin = TimeOfDay(date: now).minutesSinceMidnight
            let start = time.minutesSinceMidnight
            let slot = "\(key)|\(dayKey)|\(time.slotKey)"
            if nowMin >= start && nowMin < start + slotWindowMinutes && !firedSlots.contains(slot) {
                return slot
            }
            return nil

        case .battery(let threshold):
            guard let b = BatteryMonitor.snapshot(), b.onBattery, !b.isCharging, b.percent <= threshold else { return nil }
            if let last = lastFired[key], now.timeIntervalSince(last) < 45 * 60 { return nil }
            return "battery"
        }
    }

    private func present(_ nudge: Nudge, key: String, slot: String? = nil) {
        lastFired[key] = Date()
        if let slot { firedSlots.insert(slot) }
        shownToday += 1
        lastMessage[key] = nudge.message
        notch.show(nudge)
    }

    // MARK: - Message assembly

    private func makeNudge(for config: ReminderConfig, settings: AppSettings) -> Nudge {
        let pro = LicenseManager.shared.isPro
        let tone = pro || !settings.tone.isPro ? settings.tone : .soft
        var pool = pro ? config.customMessages.compactMap(Line.parseCustom) : []
        if !config.useOnlyCustom || pool.isEmpty {
            pool += MessageLibrary.messages(for: config.kind, language: settings.language, tone: tone)
        }
        let line = pick(from: pool, avoiding: lastMessage[config.kind.rawValue])
        return Nudge(sourceKey: config.kind.rawValue, kind: config.kind, speaker: settings.resolvedPapaName,
                     message: line.text.substituting(settings: settings),
                     subtitle: line.english?.substituting(settings: settings),
                     expression: config.kind.expression(for: tone), symbol: config.kind.symbol)
    }

    private func makeNudge(for custom: CustomReminder, settings: AppSettings) -> Nudge {
        let pool = custom.messages.compactMap(Line.parseCustom)
        let line = pool.isEmpty ? Line(custom.title) : pick(from: pool, avoiding: lastMessage[custom.id.uuidString])
        return Nudge(sourceKey: custom.id.uuidString, kind: nil, speaker: settings.resolvedPapaName,
                     message: line.text.substituting(settings: settings),
                     subtitle: line.english?.substituting(settings: settings),
                     expression: custom.expression, symbol: "star.fill")
    }

    private func pick(from pool: [Line], avoiding last: String?) -> Line {
        guard !pool.isEmpty else { return Line("...") }
        if pool.count > 1, let last {
            let others = pool.filter { $0.text != last }
            if let choice = others.randomElement() { return choice }
        }
        return pool.randomElement() ?? pool[0]
    }

    // MARK: - Housekeeping

    private func rolloverDayIfNeeded() {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let today = f.string(from: Date())
        if today != dayKey {
            dayKey = today
            firedSlots.removeAll()
            shownToday = 0
        }
    }

    private func resetIntervalBaselines() {
        let now = Date()
        for config in store.settings.reminders {
            if case .every = config.schedule { lastFired[config.kind.rawValue] = now }
        }
        for custom in store.settings.customReminders {
            if case .every = custom.schedule { lastFired[custom.id.uuidString] = now }
        }
    }
}
