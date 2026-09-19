import Foundation

/// How much is sitting in the user's Trash. Hidden files (.DS_Store) don't count.
enum TrashMonitor {
    static func itemCount() -> Int {
        let fm = FileManager.default
        guard let trash = try? fm.url(for: .trashDirectory, in: .userDomainMask, appropriateFor: nil, create: false),
              let items = try? fm.contentsOfDirectory(at: trash, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
            return 0
        }
        return items.count
    }
}
