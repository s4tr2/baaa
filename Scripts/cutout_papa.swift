import AppKit
import Vision
import CoreImage

// Usage: swift Scripts/cutout_papa.swift <input> <output.png>
// Removes the background with Vision's subject mask, trims transparent edges,
// and pads a little so the result sits nicely on the notch ledge.
let args = CommandLine.arguments
guard args.count >= 3 else { print("usage: cutout_papa.swift <input> <output.png>"); exit(1) }
let inURL = URL(fileURLWithPath: args[1])
let outURL = URL(fileURLWithPath: args[2])

guard let source = CIImage(contentsOf: inURL) else { print("cannot read input"); exit(1) }
let handler = VNImageRequestHandler(ciImage: source, options: [:])
let request = VNGenerateForegroundInstanceMaskRequest()
try handler.perform([request])
guard let result = request.results?.first else { print("no foreground found"); exit(1) }
let maskBuffer = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
let mask = CIImage(cvPixelBuffer: maskBuffer)

// Feather the mask slightly so the edges don't look cut with scissors.
let softMask = mask.applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 1.2])
    .cropped(to: source.extent)
let cutout = source.applyingFilter("CIBlendWithMask", parameters: [
    kCIInputBackgroundImageKey: CIImage(color: .clear).cropped(to: source.extent),
    kCIInputMaskImageKey: softMask,
])

let ctx = CIContext()
guard let cg = ctx.createCGImage(cutout, from: source.extent) else { print("render failed"); exit(1) }

// Trim fully transparent rows/columns.
let w = cg.width, h = cg.height
let bytesPerRow = w * 4
var data = [UInt8](repeating: 0, count: bytesPerRow * h)
let cs = CGColorSpaceCreateDeviceRGB()
let bctx = CGContext(data: &data, width: w, height: h, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: cs,
                     bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
bctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
var minX = w, minY = h, maxX = 0, maxY = 0
for y in 0..<h {
    for x in 0..<w where data[y * bytesPerRow + x * 4 + 3] > 20 {
        minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
    }
}
let pad = 8
let crop = CGRect(x: max(0, minX - pad), y: max(0, minY - pad),
                  width: min(w, maxX + pad) - max(0, minX - pad),
                  height: min(h, maxY + pad) - max(0, minY - pad))
guard let trimmed = cg.cropping(to: crop) else { print("crop failed"); exit(1) }

let rep = NSBitmapImageRep(cgImage: trimmed)
let png = rep.representation(using: .png, properties: [:])!
try png.write(to: outURL)
print("wrote \(outURL.path) \(trimmed.width)x\(trimmed.height) (from \(w)x\(h), opaque bbox \(crop))")
