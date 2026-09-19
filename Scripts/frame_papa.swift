import AppKit

// Usage: swift Scripts/frame_papa.swift <cutout.png> <output.png> [keepFraction] [targetHeight]
// Keeps the top `keepFraction` of the cutout (head through collar) and resizes.
let a = CommandLine.arguments
let inURL = URL(fileURLWithPath: a[1]), outURL = URL(fileURLWithPath: a[2])
let keep = a.count > 3 ? Double(a[3])! : 0.74
let targetH = a.count > 4 ? Int(a[4])! : 560

let src = NSImage(contentsOf: inURL)!
let rep = NSBitmapImageRep(data: src.tiffRepresentation!)!
let cg = rep.cgImage!
let cropH = Int(Double(cg.height) * keep)
let topCrop = cg.cropping(to: CGRect(x: 0, y: 0, width: cg.width, height: cropH))!  // CG origin is top-left for cropping

// Trim transparent columns so the head, not the shoulders, sets the width.
let tw = topCrop.width, th = topCrop.height, bpr = tw * 4
var px = [UInt8](repeating: 0, count: bpr * th)
let tctx = CGContext(data: &px, width: tw, height: th, bitsPerComponent: 8, bytesPerRow: bpr,
                     space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
tctx.draw(topCrop, in: CGRect(x: 0, y: 0, width: tw, height: th))
var minX = tw, maxX = 0
for y in 0..<th { for x in 0..<tw where px[y * bpr + x * 4 + 3] > 20 { minX = min(minX, x); maxX = max(maxX, x) } }
let pad = 6
let cropped = topCrop.cropping(to: CGRect(x: max(0, minX - pad), y: 0, width: min(tw, maxX + pad) - max(0, minX - pad), height: th))!
let scale = Double(targetH) / Double(cropH)
let outW = Int(Double(cropped.width) * scale), outH = targetH
let ctx = CGContext(data: nil, width: outW, height: outH, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.interpolationQuality = .high
ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: outW, height: outH))
let out = NSBitmapImageRep(cgImage: ctx.makeImage()!)
try! out.representation(using: .png, properties: [:])!.write(to: outURL)
print("wrote \(outURL.path) \(outW)x\(outH)")
