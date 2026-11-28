import AppKit
// 사용법: montage 출력.jpg 열수 칸너비 파일...
let a = CommandLine.arguments
let out = a[1], cols = Int(a[2])!, w = CGFloat(Int(a[3])!)
let files = Array(a[4...])
let h = w * 1.25
let rows = Int(ceil(Double(files.count) / Double(cols)))
let img = NSImage(size: NSSize(width: w * CGFloat(cols), height: h * CGFloat(rows)))
img.lockFocus()
NSColor(white: 0.95, alpha: 1).setFill(); NSRect(x: 0, y: 0, width: img.size.width, height: img.size.height).fill()
for (i, f) in files.enumerated() {
  guard let im = NSImage(contentsOfFile: f) else { continue }
  let c = i % cols, r = i / cols
  im.draw(in: NSRect(x: CGFloat(c) * w, y: img.size.height - CGFloat(r + 1) * h, width: w, height: h))
}
img.unlockFocus()
let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
try! rep.representation(using: .jpeg, properties: [.compressionFactor: 0.82])!.write(to: URL(fileURLWithPath: out))
