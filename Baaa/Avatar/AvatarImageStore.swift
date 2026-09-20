import AppKit
import Combine

/// Holds the optional user-supplied picture of Papa (PNG in Application Support).
@MainActor
final class AvatarImageStore: ObservableObject {
    static let shared = AvatarImageStore()

    @Published private(set) var image: NSImage?

    private let fileURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("Baaa", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("papa.png")
    }()

    /// The Papas that ship with the app, one per expression where we have a render.
    private static var bundledCache: [Expression: NSImage?] = [:]

    static func bundled(for expression: Expression) -> NSImage? {
        if let cached = bundledCache[expression] { return cached }
        let url = Bundle.main.url(forResource: "papa-\(expression.rawValue)", withExtension: "png")
        let img = url.flatMap { NSImage(contentsOf: $0) }
        bundledCache[expression] = img
        return img
    }

    /// Bundled render for this mood, falling back to the neutral face.
    /// There is no angry render yet; the stern one stands in (the notch adds the flush).
    static func bundledDefault(for expression: Expression) -> NSImage? {
        if let exact = bundled(for: expression) { return exact }
        if expression == .angry, let stern = bundled(for: .stern) { return stern }
        return bundled(for: .neutral)
    }

    private init() {
        image = NSImage(contentsOf: fileURL)
    }

    /// True when the user has imported their own picture.
    var hasImage: Bool { image != nil }

    /// What the notch should draw: the user's picture, else the bundled render for this mood.
    func effectiveImage(for expression: Expression, allowCustom: Bool = true) -> NSImage? {
        (allowCustom ? image : nil) ?? Self.bundledDefault(for: expression)
    }

    var hasAnyImage: Bool { effectiveImage(for: .neutral) != nil }

    /// Copies the chosen picture in as PNG so HEIC/JPEG/WebP sources all work later.
    func importImage(from source: URL) -> Bool {
        guard let img = NSImage(contentsOf: source),
              let tiff = img.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return false }
        do {
            try png.write(to: fileURL, options: .atomic)
            image = NSImage(contentsOf: fileURL)
            return image != nil
        } catch {
            NSLog("Baaa: could not save papa image: \(error)")
            return false
        }
    }

    func remove() {
        try? FileManager.default.removeItem(at: fileURL)
        image = nil
    }
}
