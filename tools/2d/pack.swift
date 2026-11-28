// 프레임들을 한 장으로: 색(JPEG, 흰 바탕) + 모양(투명도만 있는 PNG)
// 사용: pack dir first count cols cell out(확장자 없이) [jpg품질]
import AppKit
import UniformTypeIdentifiers
let a = CommandLine.arguments
let dir = a[1], first = Int(a[2])!, count = Int(a[3])!, cols = Int(a[4])!, cell = Int(a[5])!, out = a[6]
let q = a.count > 7 ? Double(a[7])! : 0.8
let rows = (count + cols - 1) / cols, W = cols * cell, H = rows * cell
let cs = CGColorSpaceCreateDeviceRGB()
let color = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: W * 4, space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
color.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1)); color.fill(CGRect(x: 0, y: 0, width: W, height: H))
let mask = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: W, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)!
color.interpolationQuality = .high; mask.interpolationQuality = .high
for i in 0..<count {
  let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: String(format: "%@/f%03d.png", dir, first + i)) as CFURL, nil)!
  let img = CGImageSourceCreateImageAtIndex(src, 0, nil)!
  let r = CGRect(x: (i % cols) * cell, y: H - (i / cols + 1) * cell, width: cell, height: cell)
  color.draw(img, in: r)
  // 투명도 → 회색 (그림 있는 곳 흰색)
  let m = CGContext(data: nil, width: cell, height: cell, bitsPerComponent: 8, bytesPerRow: cell, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue)!
  m.interpolationQuality = .high; m.draw(img, in: CGRect(x: 0, y: 0, width: cell, height: cell))
  let p = m.data!.assumingMemoryBound(to: UInt8.self)
  let g = CGContext(data: p, width: cell, height: cell, bitsPerComponent: 8, bytesPerRow: cell, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)!
  mask.draw(g.makeImage()!, in: r)
}
func save(_ img: CGImage, _ path: String, _ t: UTType, _ opt: [CFString: Any]) {
  let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, t.identifier as CFString, 1, nil)!
  CGImageDestinationAddImage(d, img, opt as CFDictionary); CGImageDestinationFinalize(d)
}
save(color.makeImage()!, out + ".jpg", .jpeg, [kCGImageDestinationLossyCompressionQuality: q])
// 모양: 투명도만 담은 PNG (브라우저에서 바로 '가위'로 씀)
let mp = mask.data!.assumingMemoryBound(to: UInt8.self)
var rgba = [UInt8](repeating: 0, count: W * H * 4)
for i in 0..<(W * H) { rgba[i * 4 + 3] = mp[i] }
let actx = CGContext(data: &rgba, width: W, height: H, bitsPerComponent: 8, bytesPerRow: W * 4, space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
save(actx.makeImage()!, out + "_mask.png", .png, [:])
print("sheet", W, "x", H, "frames", count)
