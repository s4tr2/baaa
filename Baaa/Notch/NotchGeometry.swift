import AppKit

struct NotchGeometry {
    let screen: NSScreen
    /// True when we are anchoring to a real hardware notch.
    let hasNotch: Bool
    /// The notch rectangle in screen coordinates (synthetic when there is no notch).
    let notchRect: CGRect

    var notchWidth: CGFloat { notchRect.width }
    var notchHeight: CGFloat { notchRect.height }

    static func current(placement: NotchPlacement) -> NotchGeometry {
        let screens = NSScreen.screens
        let notchScreen = screens.first { $0.safeAreaInsets.top > 0 }
        let mouseScreen = screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }
        let target = notchScreen ?? mouseScreen ?? NSScreen.main ?? screens[0]

        let useNotch: Bool
        switch placement {
        case .auto, .notch: useNotch = target.safeAreaInsets.top > 0
        case .floating: useNotch = false
        }

        if useNotch, let rect = hardwareNotchRect(on: target) {
            return NotchGeometry(screen: target, hasNotch: true, notchRect: rect)
        }

        // Synthetic anchor: a 200pt wide, menu-bar-high area at the top centre.
        let menuBarHeight = target.frame.maxY - target.visibleFrame.maxY
        let width: CGFloat = 200
        let rect = CGRect(x: target.frame.midX - width / 2,
                          y: target.frame.maxY - max(menuBarHeight, 24),
                          width: width,
                          height: max(menuBarHeight, 24))
        return NotchGeometry(screen: target, hasNotch: false, notchRect: rect)
    }

    private static func hardwareNotchRect(on screen: NSScreen) -> CGRect? {
        let top = screen.safeAreaInsets.top
        guard top > 0 else { return nil }
        if let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
            let x = left.maxX
            let width = right.minX - left.maxX
            guard width > 0 else { return nil }
            return CGRect(x: x, y: screen.frame.maxY - top, width: width, height: top)
        }
        // Fallback for screens that report an inset but not the auxiliary areas.
        let width: CGFloat = 180
        return CGRect(x: screen.frame.midX - width / 2, y: screen.frame.maxY - top, width: width, height: top)
    }
}
