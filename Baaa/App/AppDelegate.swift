import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = SettingsStore.shared
    private var notch: NotchController!
    private var engine: ReminderEngine!
    private var statusBar: StatusBarController!
    private var settingsWindow: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        notch = NotchController(store: store)
        engine = ReminderEngine(store: store, notch: notch)
        statusBar = StatusBarController(store: store, engine: engine, notch: notch) { [weak self] tab in
            self?.showSettings(tab: tab)
        }
        notch.onOpenSettings = { [weak self] in self?.showSettings(tab: .papa) }
        engine.start()
        LicenseManager.shared.validateIfNeeded()

        if !store.settings.hasOnboarded {
            store.settings.hasOnboarded = true
            showSettings(tab: .papa)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self else { return }
                self.notch.show(Nudge.welcome(settings: self.store.settings))
            }
        }
    }

    /// baaa://activate?key=XXXX  — sent by the thanks page right after checkout.
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls where url.scheme == "baaa" {
            guard url.host == "activate",
                  let key = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "key" })?.value,
                  !key.isEmpty else { continue }
            showSettings(tab: .pro)
            Task { await LicenseManager.shared.activate(key: key) }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings(tab: nil)
        return true
    }

    func showSettings(tab: SettingsTab?) {
        if settingsWindow == nil {
            settingsWindow = SettingsWindowController(store: store, engine: engine, notch: notch)
        }
        settingsWindow?.show(tab: tab)
    }
}
