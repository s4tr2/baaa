import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var tabs: SettingsTabModel

    var body: some View {
        TabView(selection: $tabs.selected) {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(SettingsTab.general)
            RemindersSettingsView()
                .tabItem { Label("Reminders", systemImage: "bell.badge") }
                .tag(SettingsTab.reminders)
            MessagesSettingsView()
                .tabItem { Label("Messages", systemImage: "text.bubble") }
                .tag(SettingsTab.messages)
            PapaSettingsView()
                .tabItem { Label("Papa", systemImage: "mustache.fill") }
                .tag(SettingsTab.papa)
            ProSettingsView()
                .tabItem { Label("Pro", systemImage: "seal.fill") }
                .tag(SettingsTab.pro)
            AboutView()
                .tabItem { Label("About", systemImage: "info.circle") }
                .tag(SettingsTab.about)
        }
        .frame(minWidth: 720, minHeight: 540)
    }
}

// MARK: - General

struct GeneralSettingsView: View {
    @EnvironmentObject private var store: SettingsStore
    @EnvironmentObject private var engine: ReminderEngine
    @EnvironmentObject private var license: LicenseManager
    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    var body: some View {
        Form {
            Section("Voice") {
                Picker("Language", selection: $store.settings.language) {
                    ForEach(Language.allCases) { Text($0.displayName).tag($0) }
                }
                Picker("Tone", selection: $store.settings.tone) {
                    ForEach(Tone.allCases) { t in
                        Text(t.isPro && !license.isPro ? "\(t.displayName)  (Pro)" : t.displayName).tag(t)
                    }
                }
                Text(store.settings.tone.blurb)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                if store.settings.tone.isPro && !license.isPro {
                    ProUpsell(feature: .tones)
                    Text("Until then he speaks as Soft Papa.").font(.caption).foregroundStyle(.secondary)
                }
                if store.settings.tone == .strict && license.isPro {
                    Toggle("Chappal Treatment", isOn: $store.settings.chappalTreatment)
                    HStack {
                        Text("Ignore him twice and the chappal flies out of the notch. Cartoon chappal, two throws, nobody gets hurt. Done resets his patience; snoozing is allowed.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Show me") { engine.previewChappalTreatment() }
                            .disabled(!store.settings.chappalTreatment)
                    }
                }
                HStack {
                    Text("What he calls you")
                    Spacer()
                    TextField(store.settings.language.defaultChildName, text: $store.settings.childName)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 180)
                }
            }

            Section("Quiet hours") {
                Toggle("Papa stays quiet at night", isOn: $store.settings.quietHours.enabled)
                TimeRow(label: "From", time: $store.settings.quietHours.start)
                    .disabled(!store.settings.quietHours.enabled)
                TimeRow(label: "Until", time: $store.settings.quietHours.end)
                    .disabled(!store.settings.quietHours.enabled)
                Text("Bedtime and good-morning nudges are allowed through so they can actually happen.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Pacing") {
                Stepper("At most \(store.settings.dailyLimit) nudges a day", value: $store.settings.dailyLimit, in: 1...60)
                HStack {
                    Text("Stays on screen for")
                    Slider(value: $store.settings.displaySeconds, in: 4...20, step: 1)
                    Text("\(Int(store.settings.displaySeconds)) s").monospacedDigit().frame(width: 36, alignment: .trailing)
                }
                Toggle("Play a soft sound", isOn: $store.settings.soundEnabled)
            }

            Section("Where he appears") {
                Picker("Position", selection: $store.settings.placement) {
                    ForEach(NotchPlacement.allCases) { Text($0.displayName).tag($0) }
                }
                Button("Preview in notch") { engine.nudgeNow() }
            }

            Section("System") {
                Toggle("Launch Baaapp at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, new in
                        if !LaunchAtLogin.set(new) { launchAtLogin = LaunchAtLogin.isEnabled }
                    }
                HStack {
                    Text("Shown today: \(engine.shownToday)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Reset all settings", role: .destructive) { store.resetToDefaults() }
                }
            }
        }
        .formStyle(.grouped)
    }
}

struct TimeRow: View {
    let label: String
    @Binding var time: TimeOfDay

    var body: some View {
        DatePicker(label, selection: Binding(
            get: { time.date() },
            set: { time = TimeOfDay(date: $0) }
        ), displayedComponents: .hourAndMinute)
    }
}

// MARK: - Reminders

struct RemindersSettingsView: View {
    @EnvironmentObject private var store: SettingsStore
    @EnvironmentObject private var engine: ReminderEngine
    @EnvironmentObject private var license: LicenseManager

    var body: some View {
        Form {
            Section {
                ForEach(ReminderKind.allCases) { kind in
                    ReminderRow(config: store.binding(for: kind), locked: kind.isPro && !license.isPro) {
                        engine.nudgeNow(kind: kind)
                    }
                }
            } header: {
                Text("Built-in")
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Interval reminders count only active time. Nothing fires while you're away from the Mac.")
                    if !license.isPro { ProUpsell(feature: .advancedReminders) }
                }
            }

            Section {
                ForEach(store.settings.customReminders) { custom in
                    if let binding = store.binding(forCustom: custom.id) {
                        CustomReminderRow(reminder: binding,
                                          onPreview: { engine.preview(customReminder: binding.wrappedValue) },
                                          onDelete: { store.settings.customReminders.removeAll { $0.id == custom.id } })
                    }
                }
                Button {
                    store.settings.customReminders.append(CustomReminder())
                } label: {
                    Label("Add your own reminder", systemImage: "plus.circle.fill")
                }
                .disabled(!license.isPro)
            } header: {
                Text("Your reminders")
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Medicines, standing up for the delivery guy, watering Mummy's tulsi. Papa will say whatever you write.")
                    if !license.isPro { ProUpsell(feature: .customReminders) }
                }
            }
        }
        .formStyle(.grouped)
    }
}

private struct ReminderRow: View {
    @Binding var config: ReminderConfig
    var locked = false
    var onPreview: () -> Void
    @State private var expanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            ScheduleEditor(schedule: $config.schedule)
            HStack {
                Spacer()
                Button("Preview") { onPreview() }
                    .controlSize(.small)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: config.kind.symbol)
                    .frame(width: 22)
                    .foregroundStyle(config.enabled ? Color.accentColor : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(config.kind.title)
                        if locked { Image(systemName: "lock.fill").font(.caption2).foregroundStyle(.secondary) }
                    }
                    Text(locked ? "Baaapp Pro" : (config.enabled ? config.schedule.summary : "Off"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: $config.enabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .disabled(locked)
            }
        }
        .disabled(locked)
    }
}

private struct CustomReminderRow: View {
    @Binding var reminder: CustomReminder
    var onPreview: () -> Void
    var onDelete: () -> Void
    @State private var expanded = true

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            TextField("Title", text: $reminder.title)
            ScheduleEditor(schedule: $reminder.schedule, allowBattery: false)
            Picker("Papa's face", selection: $reminder.expression) {
                ForEach(Expression.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
            }
            MessageListEditor(messages: $reminder.messages, placeholder: "e.g. {name}, did you take your medicine?")
            HStack {
                Button("Delete", role: .destructive) { onDelete() }.controlSize(.small)
                Spacer()
                Button("Preview") { onPreview() }.controlSize(.small)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .frame(width: 22)
                    .foregroundStyle(reminder.enabled ? Color.accentColor : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(reminder.title.isEmpty ? "Untitled" : reminder.title)
                    Text(reminder.enabled ? reminder.schedule.summary : "Off")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: $reminder.enabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
        }
    }
}

struct ScheduleEditor: View {
    @Binding var schedule: Schedule
    var allowBattery = true

    private enum Mode: String, CaseIterable, Identifiable {
        case every = "Every few hours", at = "At fixed times", weekly = "Once a week", battery = "On low battery",
             charged = "When fully charged", trash = "When the Trash piles up"
        var id: String { rawValue }
        var needsHardware: Bool { self == .battery || self == .charged || self == .trash }
    }

    private var mode: Mode {
        switch schedule {
        case .every: return .every
        case .at: return .at
        case .weekly: return .weekly
        case .battery: return .battery
        case .charged: return .charged
        case .trash: return .trash
        }
    }

    var body: some View {
        Picker("Schedule", selection: Binding(get: { mode }, set: { switchMode($0) })) {
            ForEach(Mode.allCases.filter { allowBattery || !$0.needsHardware }) { Text($0.rawValue).tag($0) }
        }

        switch schedule {
        case .every(let minutes):
            Picker("Interval", selection: Binding(
                get: { minutes },
                set: { schedule = .every(minutes: $0) }
            )) {
                ForEach([20, 30, 45, 60, 90, 120, 180, 240], id: \.self) { m in
                    Text(Schedule.every(minutes: m).summary).tag(m)
                }
            }

        case .at(let times):
            ForEach(Array(times.enumerated()), id: \.offset) { idx, t in
                HStack {
                    TimeRow(label: "Time \(idx + 1)", time: Binding(
                        get: { times.indices.contains(idx) ? times[idx] : t },
                        set: { new in
                            var copy = times
                            if copy.indices.contains(idx) { copy[idx] = new }
                            schedule = .at(times: copy)
                        }
                    ))
                    if times.count > 1 {
                        Button {
                            var copy = times
                            copy.remove(at: idx)
                            schedule = .at(times: copy)
                        } label: { Image(systemName: "minus.circle.fill") }
                        .buttonStyle(.borderless)
                    }
                }
            }
            Button {
                var copy = times
                let last = copy.last ?? TimeOfDay(hour: 12)
                copy.append(TimeOfDay(hour: min(23, last.hour + 4), minute: last.minute))
                schedule = .at(times: copy)
            } label: { Label("Add a time", systemImage: "plus") }
            .buttonStyle(.borderless)

        case .weekly(let weekday, let time):
            Picker("Day", selection: Binding(get: { weekday }, set: { schedule = .weekly(weekday: $0, time: time) })) {
                ForEach(1...7, id: \.self) { d in Text(Calendar.current.weekdaySymbols[d - 1]).tag(d) }
            }
            TimeRow(label: "Time", time: Binding(get: { time }, set: { schedule = .weekly(weekday: weekday, time: $0) }))

        case .battery(let threshold):
            HStack {
                Text("Below")
                Slider(value: Binding(get: { Double(threshold) }, set: { schedule = .battery(threshold: Int($0)) }), in: 5...50, step: 5)
                Text("\(threshold)%").monospacedDigit().frame(width: 40, alignment: .trailing)
            }

        case .charged(let threshold):
            HStack {
                Text("Plugged in at or above")
                Slider(value: Binding(get: { Double(threshold) }, set: { schedule = .charged(threshold: Int($0)) }), in: 80...100, step: 5)
                Text("\(threshold)%").monospacedDigit().frame(width: 40, alignment: .trailing)
            }
            Text("At 100% he also trusts macOS's own \"fully charged\" flag, so optimised charging still counts.")
                .font(.caption).foregroundStyle(.secondary)

        case .trash(let minItems):
            Picker("Nag when the Trash has", selection: Binding(get: { minItems }, set: { schedule = .trash(minItems: $0) })) {
                ForEach([1, 5, 10, 25, 50, 100], id: \.self) { n in
                    Text(n == 1 ? "anything in it" : "\(n) or more items").tag(n)
                }
            }
        }
    }

    private func switchMode(_ m: Mode) {
        switch m {
        case .every: schedule = .every(minutes: 60)
        case .at: schedule = .at(times: [TimeOfDay(hour: 13)])
        case .weekly: schedule = .weekly(weekday: 1, time: TimeOfDay(hour: 11))
        case .battery: schedule = .battery(threshold: 20)
        case .charged: schedule = .charged(threshold: 100)
        case .trash: schedule = .trash(minItems: 10)
        }
    }
}

struct MessageListEditor: View {
    @Binding var messages: [String]
    var placeholder: String

    var body: some View {
        ForEach(messages.indices, id: \.self) { idx in
            HStack(alignment: .top) {
                TextField(placeholder, text: Binding(
                    get: { messages.indices.contains(idx) ? messages[idx] : "" },
                    set: { if messages.indices.contains(idx) { messages[idx] = $0 } }
                ), axis: .vertical)
                .lineLimit(1...3)
                Button {
                    if messages.indices.contains(idx) { messages.remove(at: idx) }
                } label: { Image(systemName: "minus.circle.fill") }
                .buttonStyle(.borderless)
                .help("Remove this message")
            }
        }
        Button {
            messages.append("")
        } label: { Label("Add a message", systemImage: "plus") }
        .buttonStyle(.borderless)
    }
}

// MARK: - Messages

struct MessagesSettingsView: View {
    @EnvironmentObject private var store: SettingsStore
    @EnvironmentObject private var engine: ReminderEngine
    @EnvironmentObject private var license: LicenseManager
    @State private var kind: ReminderKind = .meal

    var body: some View {
        HSplitView {
            List(ReminderKind.allCases, selection: $kind) { k in
                Label(k.title, systemImage: k.symbol).tag(k)
            }
            .listStyle(.sidebar)
            .frame(minWidth: 170, maxWidth: 200)

            Form {
                let binding = store.binding(for: kind)
                Section {
                    Text(kind.subtitle).foregroundStyle(.secondary)
                    Toggle("Only use my messages for this reminder", isOn: binding.useOnlyCustom)
                        .disabled(!license.isPro || binding.wrappedValue.customMessages.allSatisfy { $0.trimmingCharacters(in: .whitespaces).isEmpty })
                } header: {
                    Text("Your messages for \(kind.title.lowercased())")
                } footer: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Write {name} where he should say your name, and {papa} for his. Add two slashes and an English line to show a grey translation underneath. Otherwise he mixes these in with the built-in lines in \(store.settings.language.displayName).")
                        if !license.isPro { ProUpsell(feature: .customMessages) }
                    }
                }

                Section {
                    MessageListEditor(messages: binding.customMessages, placeholder: "Khaana khaya? // Have you eaten?")
                        .disabled(!license.isPro)
                    HStack {
                        Spacer()
                        Button("Preview a built-in line") { engine.nudgeNow(kind: kind) }
                        Button("Preview my last line") {
                            if let last = binding.wrappedValue.customMessages.last(where: { !$0.isEmpty }) {
                                engine.preview(message: last, expression: kind.expression(for: store.settings.tone))
                            }
                        }
                        .disabled(binding.wrappedValue.customMessages.allSatisfy { $0.isEmpty })
                    }
                }

                Section("Built-in lines he currently knows") {
                    ForEach(MessageLibrary.messages(for: kind, language: store.settings.language, tone: store.settings.tone), id: \.self) { line in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(line.text.substituting(settings: store.settings))
                                .font(.callout)
                            if let en = line.english {
                                Text(en.substituting(settings: store.settings))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
    }
}

// MARK: - Papa

struct PapaSettingsView: View {
    @EnvironmentObject private var store: SettingsStore
    @EnvironmentObject private var engine: ReminderEngine
    @EnvironmentObject private var license: LicenseManager
    @ObservedObject private var images = AvatarImageStore.shared
    @State private var previewExpression: Expression = .neutral

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 14) {
                // Mock of the notch block so you see exactly how he will peek out.
                ZStack(alignment: .bottom) {
                    NotchShape(flare: NotchController.flare, bottomRadius: 26)
                        .fill(.black)
                        .frame(width: 210 + NotchController.flare * 2, height: 32 + NotchController.blockBodyHeight)
                    PeekingPapaView(config: store.settings.avatar,
                                    expression: previewExpression,
                                    image: images.effectiveImage(for: previewExpression, allowCustom: license.isPro),
                                    width: 210 - 16,
                                    height: NotchController.blockBodyHeight - 4)
                        .padding(.bottom, 2)
                }
                .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
                .padding(.top, 8)

                Text(store.settings.resolvedPapaName)
                    .font(.title2.weight(.semibold))
                Picker("", selection: $previewExpression) {
                    ForEach(Expression.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 270)
                Button("Show him in the notch") { engine.nudgeNow() }
                Spacer()
            }
            .frame(width: 310)
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))

            Form {
                Section("Name") {
                    HStack {
                        Text("You call him")
                        Spacer()
                        TextField(store.settings.language.defaultPapaName, text: $store.settings.papaName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 180)
                    }
                    Text("Papa, Appa, Baba, Bapu, Daddy, Abba… whatever it is at home.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Section {
                    HStack(spacing: 12) {
                        if let img = images.effectiveImage(for: .neutral, allowCustom: license.isPro) {
                            Image(nsImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 56, height: 56)
                                .background(RoundedRectangle(cornerRadius: 10).fill(.black))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                                .foregroundStyle(.secondary)
                                .frame(width: 56, height: 56)
                                .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Button("Choose picture…") { choosePicture() }
                                    .disabled(!license.isPro)
                                if images.hasImage {
                                    Button("Back to the built-in Papa") {
                                        images.remove()
                                        store.settings.avatar.imageZoom = 1
                                        store.settings.avatar.imageOffsetY = 0
                                    }
                                }
                            }
                        }
                    }
                    if images.hasAnyImage {
                        HStack {
                            Text("Size")
                            Slider(value: $store.settings.avatar.imageZoom, in: 0.6...1.8)
                        }
                        HStack {
                            Text("Peek")
                            Slider(value: $store.settings.avatar.imageOffsetY, in: -40...60)
                            Button("Reset") {
                                store.settings.avatar.imageZoom = 1
                                store.settings.avatar.imageOffsetY = 0
                            }.controlSize(.small)
                        }
                    }
                } header: {
                    Text("Picture")
                } footer: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Baaapp ships with a 3D Papa whose face changes with the reminder. Prefer your own? Pick any PNG; a transparent or black background blends into the notch.")
                        if !license.isPro { ProUpsell(feature: .customPicture) }
                    }
                }

            }
            .formStyle(.grouped)
        }
    }

    private func choosePicture() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic, .tiff, .webP, .gif]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Pick a picture of Papa. Transparent or black background works best."
        NSApp.activate(ignoringOtherApps: true)
        if panel.runModal() == .OK, let url = panel.url {
            if images.importImage(from: url) {
                store.settings.avatar.useImage = true
            }
        }
    }

}

// MARK: - About

struct AboutView: View {
    @EnvironmentObject private var store: SettingsStore

    var body: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.black).frame(width: 150, height: 118)
                PeekingPapaView(config: store.settings.avatar, expression: .proud,
                                image: AvatarImageStore.shared.effectiveImage(for: .proud),
                                width: 134, height: 114)
                    .padding(.bottom, 2)
            }
            Text("Baaapp").font(.system(size: 28, weight: .bold))
            Text("Gentle (and not so gentle) nudges from Papa, straight from your Mac's notch.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 380)
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1")")
                .font(.footnote)
                .foregroundStyle(.tertiary)
            Divider().frame(width: 240)
            VStack(spacing: 4) {
                Text("Everything stays on this Mac. No account, no analytics, no microphone.")
                Text("Inspired by Maaa. Same love, different parent.")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
