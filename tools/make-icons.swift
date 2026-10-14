// Draws the extension and toolbar icons into extension/icons/.
//   swift tools/make-icons.swift
import AppKit

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let out = root.appendingPathComponent("extension/icons")
try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

func png(_ size: Int, _ name: String, draw: (CGContext, CGFloat) -> Void) throws {
  let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                             samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                             colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
  let ctx = NSGraphicsContext(bitmapImageRep: rep)!
  NSGraphicsContext.current = ctx
  draw(ctx.cgContext, CGFloat(size))
  ctx.flushGraphics()
  try rep.representation(using: .png, properties: [:])!.write(to: out.appendingPathComponent("\(name).png"))
}

// Crescent: a disc with an offset disc punched out of it.
func crescent(_ c: CGContext, center: CGPoint, radius r: CGFloat) {
  c.addEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r))
  c.fillPath()
  c.setBlendMode(.clear)
  let cut = r * 0.86
  c.addEllipse(in: CGRect(x: center.x - r * 0.38 - cut + r * 0.62, y: center.y + r * 0.30 - cut, width: 2 * cut, height: 2 * cut))
  c.fillPath()
  c.setBlendMode(.normal)
}

let red = CGColor(red: 0xE6 / 255, green: 0x00 / 255, blue: 0x23 / 255, alpha: 1)

for size in [16, 32, 48, 96, 128, 256, 512, 1024] {
  try png(size, "icon-\(size)") { c, s in
    // Tile
    let inset = s * 0.08
    let tile = CGRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)
    let path = CGPath(roundedRect: tile, cornerWidth: tile.width * 0.24, cornerHeight: tile.width * 0.24, transform: nil)
    c.saveGState()
    c.addPath(path)
    c.clip()
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                              colors: [CGColor(gray: 0.13, alpha: 1), CGColor(gray: 0.02, alpha: 1)] as CFArray,
                              locations: [0, 1])!
    c.drawLinearGradient(gradient, start: CGPoint(x: 0, y: s), end: CGPoint(x: 0, y: 0), options: [])
    c.restoreGState()
    // Moon (drawn in its own transparency layer so the cut-out doesn't punch through the tile)
    c.beginTransparencyLayer(auxiliaryInfo: nil)
    c.setFillColor(red)
    // Nudged up-right: the crescent's visible mass sits low-left of its disc.
    crescent(c, center: CGPoint(x: s * 0.53, y: s * 0.53), radius: tile.width * 0.30)
    c.endTransparencyLayer()
  }
}

// Toolbar: monochrome glyph on transparent (Safari treats it as a template image).
for size in [16, 19, 32, 38, 48] {
  try png(size, "toolbar-\(size)") { c, s in
    c.setFillColor(CGColor(gray: 0, alpha: 1))
    crescent(c, center: CGPoint(x: s * 0.5, y: s * 0.5), radius: s * 0.40)
  }
}
print("icons written to \(out.path)")
