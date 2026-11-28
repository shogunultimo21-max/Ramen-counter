import AppKit
// 어두운 바탕에 아이콘들을 늘어놓아 투명 처리 확인: dark 출력.png 열수 칸 파일...
let a = CommandLine.arguments, cols = Int(a[2])!, w = CGFloat(Int(a[3])!), files = Array(a[4...])
let rows = (files.count + cols - 1) / cols
let img = NSImage(size: NSSize(width: CGFloat(cols) * w, height: CGFloat(rows) * w))
img.lockFocus(); NSColor(calibratedRed: 0.16, green: 0.11, blue: 0.08, alpha: 1).setFill(); NSRect(x: 0, y: 0, width: img.size.width, height: img.size.height).fill()
for (i, f) in files.enumerated() { if let im = NSImage(contentsOfFile: f) { im.draw(in: NSRect(x: CGFloat(i % cols) * w, y: img.size.height - CGFloat(i / cols + 1) * w, width: w, height: w)) } }
img.unlockFocus()
let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!; try! rep.representation(using: .jpeg, properties: [:])!.write(to: URL(fileURLWithPath: a[1]))
