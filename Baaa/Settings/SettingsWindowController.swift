import AppKit
import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general, reminders, messages, papa, pro, about
    var id: String { rawValue }
}

@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    private let window: NSWindow
    private let tabModel = SettingsTabModel()

    init(store: SettingsStore, engine: ReminderEngine, notch: NotchController) {
        let root = SettingsView()
            .environmentObject(store)
            .environmentObject(engine)
            .environmentObject(tabModel)
            .environmentObject(LicenseManager.shared)
        let host = NSHostingController(rootView: root)
        window = NSWindow(contentViewController: host)
        window.title = "Baaa"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 720, height: 540))
        window.isReleasedWhenClosed = false
        window.center()
        super.init()
        window.delegate = self
    }

    func show(tab: SettingsTab?) {
        if let tab { tabModel.selected = tab }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}

final class SettingsTabModel: ObservableObject {
    @Published var selected: SettingsTab = .general
}
