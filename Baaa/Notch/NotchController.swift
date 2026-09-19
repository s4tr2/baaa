import AppKit
import SwiftUI
import Combine

@MainActor
final class NotchViewModel: ObservableObject {
    @Published var nudge: Nudge?
    @Published var expanded = false
    @Published var hovering = false
    @Published var hasNotch = true
    @Published var notchWidth: CGFloat = 200
    @Published var notchHeight: CGFloat = 32
    @Published var avatar = AvatarConfig()
    @Published var image: NSImage?
    @Published var moodImage: NSImage?
    @Published var moodRevealed = false
    @Published var doneLabel = "OK"
    @Published var snoozeLabel = "10 min"

    /// Frames (SwiftUI global coordinates) of the two solid parts, for hit testing.
    var blockRect: CGRect = .zero
    var bubbleRect: CGRect = .zero

    var onDone: (() -> Void)?
    var onSnooze: (() -> Void)?
    var onOpenSettings: (() -> Void)?
}

/// Only the block and the bubble take clicks; everything else falls through to
/// whatever is behind the transparent panel.
final class NotchHostingView<Content: View>: NSHostingView<Content> {
    var hitRegions: () -> [CGRect] = { [] }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        let flippedY = isFlipped ? local.y : bounds.height - local.y
        let p = CGPoint(x: local.x, y: flippedY)
        guard hitRegions().contains(where: { $0.insetBy(dx: -4, dy: -4).contains(p) }) else { return nil }
        return super.hitTest(point)
    }
}

@MainActor
final class NotchController {
    /// Layout constants shared with NotchView.
    static let blockMinWidth: CGFloat = 210
    static let blockBodyHeight: CGFloat = 118
    static let bubbleWidth: CGFloat = 320
    /// Distance from the black body of the block to the tip of the bubble's tail.
    static let bubbleGap: CGFloat = 6
    static let flare: CGFloat = 14
    static let shadowPad: CGFloat = 30
    static let panelBodyHeight: CGFloat = 230

    static func blockWidth(forNotch notchWidth: CGFloat) -> CGFloat {
        max(blockMinWidth, notchWidth + 36)
    }

    let model = NotchViewModel()

    var onSnooze: ((Nudge) -> Void)?
    var onDone: ((Nudge) -> Void)?
    var onOpenSettings: (() -> Void)?

    private let store: SettingsStore
    private var panel: NotchPanel?
    private var hideTimer: Timer?
    private var moodWork: DispatchWorkItem?
    private var cancellables = Set<AnyCancellable>()

    private(set) var isVisible = false

    init(store: SettingsStore) {
        self.store = store
        model.onDone = { [weak self] in self?.tapDone() }
        model.onSnooze = { [weak self] in self?.tapSnooze() }
        model.onOpenSettings = { [weak self] in
            self?.hide()
            self?.onOpenSettings?()
        }
        model.$hovering
            .removeDuplicates()
            .sink { [weak self] hovering in
                guard let self, self.isVisible else { return }
                if hovering {
                    self.hideTimer?.invalidate()
                } else {
                    self.scheduleHide(after: 1.8)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Show / hide

    func show(_ nudge: Nudge) {
        let settings = store.settings
        let geo = NotchGeometry.current(placement: settings.placement)

        model.avatar = settings.avatar
        // He pops out with his usual face, then reacts a beat later.
        let store = AvatarImageStore.shared
        let pro = LicenseManager.shared.isPro
        model.image = store.effectiveImage(for: .neutral, allowCustom: pro)
        model.moodImage = store.effectiveImage(for: nudge.expression, allowCustom: pro)
        model.moodRevealed = false
        moodWork?.cancel()
        let reveal = DispatchWorkItem { [weak self] in
            withAnimation(.easeInOut(duration: 0.45)) { self?.model.moodRevealed = true }
        }
        moodWork = reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: reveal)
        model.hasNotch = geo.hasNotch
        model.notchWidth = geo.notchWidth
        model.notchHeight = geo.notchHeight
        let pack = MessageLibrary.pack(settings.language)
        model.doneLabel = pack.done
        model.snoozeLabel = pack.snooze
        model.nudge = nudge

        let panel = ensurePanel()
        panel.setFrame(frame(for: geo), display: false)

        hideTimer?.invalidate()
        isVisible = true

        if panel.isVisible {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                model.expanded = true
            }
        } else {
            model.expanded = false
            panel.alphaValue = 1
            panel.orderFrontRegardless()
            DispatchQueue.main.async { [weak self] in
                withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                    self?.model.expanded = true
                }
            }
        }

        if settings.soundEnabled {
            NSSound(named: "Pop")?.play()
        }
        scheduleHide(after: max(4, settings.displaySeconds))
    }

    func hide() {
        hideTimer?.invalidate()
        moodWork?.cancel()
        guard isVisible else { return }
        isVisible = false
        // Quick, clean retract straight back into the notch.
        withAnimation(.easeInOut(duration: 0.26)) {
            model.expanded = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self, !self.isVisible else { return }
            self.panel?.orderOut(nil)
            self.model.nudge = nil
            self.model.hovering = false
            self.model.moodRevealed = false
        }
    }

    /// Flash a reaction face, then retract.
    private func react(with expression: Expression, then completion: @escaping () -> Void) {
        hideTimer?.invalidate()
        moodWork?.cancel()
        let store = AvatarImageStore.shared
        guard model.avatar.useImage,
              let face = store.effectiveImage(for: expression, allowCustom: LicenseManager.shared.isPro),
              face !== model.moodImage else {
            completion()
            return
        }
        model.moodImage = face
        withAnimation(.easeInOut(duration: 0.25)) { model.moodRevealed = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65, execute: completion)
    }

    private func scheduleHide(after seconds: TimeInterval) {
        hideTimer?.invalidate()
        let t = Timer(timeInterval: seconds, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.model.hovering { return }
                self.hide()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        hideTimer = t
    }

    private func tapDone() {
        if let n = model.nudge { onDone?(n) }
        react(with: .happy) { [weak self] in self?.hide() }
    }

    private func tapSnooze() {
        if let n = model.nudge { onSnooze?(n) }
        react(with: .stern) { [weak self] in self?.hide() }
    }

    // MARK: - Panel plumbing

    private func ensurePanel() -> NotchPanel {
        if let panel { return panel }
        let p = NotchPanel()
        let host = NotchHostingView(rootView: NotchView(model: model))
        host.hitRegions = { [weak model] in
            guard let model else { return [] }
            return [model.blockRect, model.bubbleRect]
        }
        host.wantsLayer = true
        host.layer?.backgroundColor = .clear
        p.contentView = host
        panel = p
        return p
    }

    private func frame(for geo: NotchGeometry) -> CGRect {
        let blockWidth = Self.blockWidth(forNotch: geo.notchWidth)
        let width = Self.flare * 2 + blockWidth + Self.bubbleGap + Self.bubbleWidth + Self.shadowPad
        let x = geo.notchRect.midX - Self.flare - blockWidth / 2
        if geo.hasNotch {
            let height = geo.notchHeight + Self.panelBodyHeight
            return CGRect(x: x, y: geo.screen.frame.maxY - height, width: width, height: height)
        } else {
            let height = Self.panelBodyHeight
            let top = geo.notchRect.minY - 6
            return CGRect(x: x, y: top - height, width: width, height: height)
        }
    }
}
