import Foundation
import IOKit.ps

struct BatterySnapshot {
    var percent: Int
    var onBattery: Bool
    var isCharging: Bool
}

enum BatteryMonitor {
    static func snapshot() -> BatterySnapshot? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else {
            return nil
        }
        for source in list {
            guard let desc = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any] else { continue }
            guard let type = desc[kIOPSTypeKey] as? String, type == kIOPSInternalBatteryType else { continue }
            let current = desc[kIOPSCurrentCapacityKey] as? Int ?? 0
            let max = desc[kIOPSMaxCapacityKey] as? Int ?? 100
            let percent = max > 0 ? Int((Double(current) / Double(max) * 100).rounded()) : current
            let state = desc[kIOPSPowerSourceStateKey] as? String
            let charging = desc[kIOPSIsChargingKey] as? Bool ?? false
            return BatterySnapshot(percent: percent, onBattery: state == kIOPSBatteryPowerValue, isCharging: charging)
        }
        return nil
    }
}
