import AppKit
import SwiftUI

/// Hosts the first-launch setup. Closing the window counts as finishing,
/// so nobody gets asked twice.
@MainActor
final class OnboardingWindowController: NSObject, NSWindowDelegate {
    private let window: NSWindow
    private let onFinish: () -> Void
    private var finished = false

    init(store: SettingsStore, onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
        window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
        super.init()
        let root = OnboardingView { [weak self] in self?.finish() }
            .environmentObject(store)
            .environmentObject(LicenseManager.shared)
        window.contentViewController = NSHostingController(rootView: root)
        window.title = "Welcome to Baaapp"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        window.close()
        onFinish()
    }

    func windowWillClose(_ notification: Notification) {
        finish()
    }
}
