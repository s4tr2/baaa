import AppKit

// Renders the Baaapp app icon (a mustache on a warm saffron tile)
// at every size macOS wants, into the asset catalog.
let outDir = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "Baaa/Resources/Assets.xcassets/AppIcon.appiconset"

func draw(size: CGFloat) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else { return img }
    let s = size / 1024.0

    // macOS icon tile with rounded corners (~22.37% radius)
    let inset = 100 * s
    let tile = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let path = CGPath(roundedRect: tile, cornerWidth: tile.width * 0.2237, cornerHeight: tile.width * 0.2237, transform: nil)
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    let colors = [NSColor(red: 0.98, green: 0.62, blue: 0.20, alpha: 1).cgColor,
                  NSColor(red: 0.85, green: 0.35, blue: 0.16, alpha: 1).cgColor] as CFArray
    let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: tile.minX, y: tile.maxY), end: CGPoint(x: tile.maxX, y: tile.minY), options: [])
    ctx.restoreGState()

    // Mustache
    ctx.setFillColor(NSColor(white: 0.12, alpha: 1).cgColor)
    let m = CGMutablePath()
    let cx = 512 * s, my = 512 * s
    m.move(to: CGPoint(x: cx, y: my + 30 * s))
    m.addCurve(to: CGPoint(x: cx - 420 * s, y: my + 90 * s),
               control1: CGPoint(x: cx - 120 * s, y: my + 150 * s),
               control2: CGPoint(x: cx - 330 * s, y: my + 190 * s))
    m.addCurve(to: CGPoint(x: cx, y: my - 80 * s),
               control1: CGPoint(x: cx - 390 * s, y: my + 10 * s),
               control2: CGPoint(x: cx - 170 * s, y: my - 100 * s))
    m.addCurve(to: CGPoint(x: cx + 420 * s, y: my + 90 * s),
               control1: CGPoint(x: cx + 170 * s, y: my - 100 * s),
               control2: CGPoint(x: cx + 390 * s, y: my + 10 * s))
    m.addCurve(to: CGPoint(x: cx, y: my + 30 * s),
               control1: CGPoint(x: cx + 330 * s, y: my + 190 * s),
               control2: CGPoint(x: cx + 120 * s, y: my + 150 * s))
    m.closeSubpath()
    ctx.addPath(m)
    ctx.fillPath()

    img.unlockFocus()
    return img
}

func write(_ image: NSImage, pixels: Int, to url: URL) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: url)
}

let sizes: [(pt: Int, scale: Int)] = [(16,1),(16,2),(32,1),(32,2),(128,1),(128,2),(256,1),(256,2),(512,1),(512,2)]
var images: [[String: String]] = []
let dir = URL(fileURLWithPath: outDir)
try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
for (pt, scale) in sizes {
    let px = pt * scale
    let name = "icon_\(pt)x\(pt)@\(scale)x.png"
    write(draw(size: CGFloat(px)), pixels: px, to: dir.appendingPathComponent(name))
    images.append(["idiom": "mac", "size": "\(pt)x\(pt)", "scale": "\(scale)x", "filename": name])
}
let contents: [String: Any] = ["images": images, "info": ["version": 1, "author": "xcode"]]
let data = try! JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try! data.write(to: dir.appendingPathComponent("Contents.json"))
print("wrote \(images.count) icons to \(outDir)")
