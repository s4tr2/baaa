import Foundation
import CoreGraphics

enum IdleMonitor {
    /// Seconds since the user last touched the keyboard, mouse or trackpad.
    static var secondsIdle: TimeInterval {
        let anyEvent = CGEventType(rawValue: ~0) ?? .null
        return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyEvent)
    }
}
