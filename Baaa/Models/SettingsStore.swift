import Foundation
import Combine
import SwiftUI

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    @Published var settings: AppSettings {
        didSet { scheduleSave() }
    }

    private let defaultsKey = "app.baaa.settings.v1"
    private var saveWorkItem: DispatchWorkItem?

    private init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        } else {
            settings = AppSettings()
        }
    }

    private func scheduleSave() {
        saveWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.saveNow() }
        saveWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: item)
    }

    func saveNow() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    // MARK: - Bindings for the settings UI

    func binding(for kind: ReminderKind) -> Binding<ReminderConfig> {
        Binding(
            get: { self.settings.reminder(kind) },
            set: { newValue in
                if let idx = self.settings.reminders.firstIndex(where: { $0.kind == kind }) {
                    self.settings.reminders[idx] = newValue
                } else {
                    self.settings.reminders.append(newValue)
                }
            }
        )
    }

    func binding(forCustom id: UUID) -> Binding<CustomReminder>? {
        guard let idx = settings.customReminders.firstIndex(where: { $0.id == id }) else { return nil }
        return Binding(
            get: { self.settings.customReminders.indices.contains(idx) ? self.settings.customReminders[idx] : CustomReminder() },
            set: { newValue in
                if self.settings.customReminders.indices.contains(idx) {
                    self.settings.customReminders[idx] = newValue
                }
            }
        )
    }

    func resetToDefaults() {
        let onboarded = settings.hasOnboarded
        settings = AppSettings()
        settings.hasOnboarded = onboarded
    }
}
