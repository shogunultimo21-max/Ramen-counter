// 영상 프레임에서 같은 네모 부분만 잘라 한 장(가로 cols칸)으로 묶기 — 배경 그림 위에 그대로 겹쳐 틀 움직임(웍 등)
// rectpack dir start n x y w h cols out.jpg   (x,y,w,h = 프레임 픽셀)
import AppKit
let a = CommandLine.arguments
let dir = a[1], s = Int(a[2])!, n = Int(a[3])!
let x = Int(a[4])!, y = Int(a[5])!, w = Int(a[6])!, h = Int(a[7])!, cols = Int(a[8])!, out = a[9]
let rows = (n + cols - 1) / cols
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w * cols, pixelsHigh: h * rows, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
NSColor.black.setFill(); NSRect(x: 0, y: 0, width: w * cols, height: h * rows).fill()
for i in 0..<n {
  let img = NSImage(contentsOfFile: String(format: "%@/f%03d.png", dir, s + i))!
  let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil)!
  let crop = cg.cropping(to: CGRect(x: x, y: y, width: w, height: h))!
  let cx = (i % cols) * w, cy = (rows - 1 - i / cols) * h
  NSGraphicsContext.current!.cgContext.draw(crop, in: CGRect(x: cx, y: cy, width: w, height: h))
}
NSGraphicsContext.restoreGraphicsState()
let data = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.82])!
try! data.write(to: URL(fileURLWithPath: out))
print("sheet", w * cols, "x", h * rows, "frames", n, "bytes", data.count)
