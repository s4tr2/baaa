import AppKit

@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private let store: SettingsStore
    private let engine: ReminderEngine
    private let notch: NotchController
    private let openSettings: (SettingsTab?) -> Void
    private let item: NSStatusItem

    init(store: SettingsStore, engine: ReminderEngine, notch: NotchController, openSettings: @escaping (SettingsTab?) -> Void) {
        self.store = store
        self.engine = engine
        self.notch = notch
        self.openSettings = openSettings
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        if let button = item.button {
            let image = NSImage(systemSymbolName: "mustache.fill", accessibilityDescription: "Baaapp")
            image?.isTemplate = true
            button.image = image
            button.toolTip = "Baaapp - Papa is keeping an eye on you"
        }
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let duo = store.settings.maaJoins
        let title = engine.isPaused ? (duo ? "Maa & Papa are taking a nap" : "Papa is taking a nap")
                                    : (duo ? "Maa & Papa are watching" : "Papa is watching")
        let header = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        menu.addItem(makeItem("Nudge me now", #selector(nudgeNow), key: "n"))

        let pick = NSMenuItem(title: "Nudge me about…", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        for kind in ReminderKind.allCases {
            let mi = NSMenuItem(title: kind.title, action: #selector(nudgeKind(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = kind.rawValue
            mi.image = NSImage(systemSymbolName: kind.symbol, accessibilityDescription: nil)
            sub.addItem(mi)
        }
        sub.addItem(.separator())
        let chappal = makeItem("Chappal Treatment", #selector(chappalTreatment))
        chappal.image = NSImage(systemSymbolName: "shoe.fill", accessibilityDescription: nil)
            ?? NSImage(systemSymbolName: "flame.fill", accessibilityDescription: nil)
        sub.addItem(chappal)
        pick.submenu = sub
        menu.addItem(pick)
        menu.addItem(.separator())

        if engine.isPaused {
            menu.addItem(makeItem("Resume reminders", #selector(resume)))
        } else {
            let pause = NSMenuItem(title: "Pause reminders", action: nil, keyEquivalent: "")
            let sub = NSMenu()
            sub.addItem(makeItem("For 1 hour", #selector(pause1h)))
            sub.addItem(makeItem("For 3 hours", #selector(pause3h)))
            sub.addItem(makeItem("Until tomorrow morning", #selector(pauseTomorrow)))
            pause.submenu = sub
            menu.addItem(pause)
        }
        menu.addItem(.separator())

        if !LicenseManager.shared.isPro {
            let pro = makeItem("Get Baaapp Pro…", #selector(getPro))
            pro.image = NSImage(systemSymbolName: "seal.fill", accessibilityDescription: nil)
            menu.addItem(pro)
        }
        let maa = makeItem("Maa joins Papa", #selector(toggleMaa))
        maa.state = store.settings.maaJoins ? .on : .off
        maa.image = NSImage(systemSymbolName: "figure.2", accessibilityDescription: nil)
        menu.addItem(maa)
        let launch = makeItem("Launch at login", #selector(toggleLaunch))
        launch.state = LaunchAtLogin.isEnabled ? .on : .off
        menu.addItem(launch)
        menu.addItem(makeItem("Settings…", #selector(settings), key: ","))
        menu.addItem(.separator())
        menu.addItem(makeItem("Quit Baaapp", #selector(quit), key: "q"))
    }

    private func makeItem(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let mi = NSMenuItem(title: title, action: action, keyEquivalent: key)
        mi.target = self
        return mi
    }

    @objc private func nudgeNow() { engine.nudgeNow() }
    @objc private func nudgeKind(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? String, let kind = ReminderKind(rawValue: raw) {
            engine.nudgeNow(kind: kind)
        }
    }
    @objc private func chappalTreatment() { engine.previewChappalTreatment() }
    @objc private func resume() { engine.resume() }
    @objc private func pause1h() { engine.pause(for: 3600) }
    @objc private func pause3h() { engine.pause(for: 3 * 3600) }
    @objc private func pauseTomorrow() { engine.pauseUntilTomorrow() }
    @objc private func toggleMaa() {
        store.settings.maaJoins.toggle()
        if store.settings.maaJoins { engine.nudgeNow() }
    }
    @objc private func toggleLaunch() { LaunchAtLogin.set(!LaunchAtLogin.isEnabled) }
    @objc private func settings() { openSettings(nil) }
    @objc private func getPro() { openSettings(.pro) }
    @objc private func quit() { NSApp.terminate(nil) }
}
