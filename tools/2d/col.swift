import AppKit
let r = NSBitmapImageRep(data: try! Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))!
let x = Int(CommandLine.arguments[2])!
for y in stride(from: 270, to: r.pixelsHigh, by: 4) { let c = r.colorAt(x: x, y: y)!; print(y, Int(c.redComponent*255), Int(c.greenComponent*255), Int(c.blueComponent*255), Int(c.alphaComponent*255)) }
