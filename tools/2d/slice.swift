// 아이콘 묶음 그림(격자)을 칸별로 잘라 배경(흰색 계열)을 투명하게 하고 정사각형 PNG로 저장
// 사용: slice <sheet.png> <cols> <rows> <outDir> <size> name1 name2 ... ("-" 은 건너뜀)
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let a = CommandLine.arguments
guard a.count >= 6 else { print("usage: slice sheet cols rows outDir size names..."); exit(1) }
let url = URL(fileURLWithPath: a[1]), cols = Int(a[2])!, rows = Int(a[3])!, outDir = a[4], size = Int(a[5])!
let names = Array(a.dropFirst(6))
guard let src = CGImageSourceCreateWithURL(url as CFURL, nil), let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { print("cannot read"); exit(1) }
let W = img.width, H = img.height
let cs = CGColorSpaceCreateDeviceRGB()
var px = [UInt8](repeating: 0, count: W * H * 4)
let ctx = CGContext(data: &px, width: W, height: H, bitsPerComponent: 8, bytesPerRow: W * 4, space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.draw(img, in: CGRect(x: 0, y: 0, width: W, height: H))
// 배경색: 네 모서리의 평균
func at(_ x: Int, _ y: Int) -> (Int, Int, Int) { let i = (y * W + x) * 4; return (Int(px[i]), Int(px[i + 1]), Int(px[i + 2])) }
var br = 0, bg = 0, bb = 0
// BGTOP=1: 위쪽 두 모서리만 (아래쪽에 탁자 등이 깔린 그림)
let corners = ProcessInfo.processInfo.environment["BGTOP"] == "1" ? [(2, 2), (W - 3, 2)] : [(2, 2), (W - 3, 2), (2, H - 3), (W - 3, H - 3)]
for (x, y) in corners { let c = at(x, y); br += c.0; bg += c.1; bb += c.2 }
br /= corners.count; bg /= corners.count; bb /= corners.count
func isBg(_ x: Int, _ y: Int, _ tol: Int) -> Bool { let c = at(x, y); return abs(c.0 - br) + abs(c.1 - bg) + abs(c.2 - bb) < tol }
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
let inset = W / cols / 28 // 칸 사이 선이 들어가지 않게 가장자리를 조금 버림
let cw = W / cols - inset * 2, ch = H / rows - inset * 2
for r in 0..<rows { for c in 0..<cols {
  let k = r * cols + c
  guard k < names.count, names[k] != "-" else { continue }
  let x0 = c * (W / cols) + inset, y0 = r * (H / rows) + inset
  // 칸 테두리에서 시작하는 배경 채우기 (안쪽의 흰 부분은 테두리선에 막혀 남음)
  var alpha = [UInt8](repeating: 255, count: cw * ch)
  var stack: [(Int, Int)] = []
  for x in 0..<cw { stack.append((x, 0)); stack.append((x, ch - 1)) }
  for y in 0..<ch { stack.append((0, y)); stack.append((cw - 1, y)) }
  while let (x, y) = stack.popLast() {
    if x < 0 || y < 0 || x >= cw || y >= ch { continue }
    let i = y * cw + x
    if alpha[i] == 0 || !isBg(x0 + x, y0 + y, 60) { continue }
    alpha[i] = 0
    stack.append((x + 1, y)); stack.append((x - 1, y)); stack.append((x, y + 1)); stack.append((x, y - 1))
  }
  // PANEL=1: 가장 큰 덩어리(장면 그림)만 남기고 글자 같은 작은 조각은 버림
  if ProcessInfo.processInfo.environment["PANEL"] == "1" {
    var lab = [Int32](repeating: -1, count: cw * ch); var best = -1, bestN = 0, id: Int32 = 0
    for start in 0..<(cw * ch) where alpha[start] > 0 && lab[start] < 0 {
      var q = [start]; lab[start] = id; var n = 0
      while let i = q.popLast() { n += 1; let x = i % cw, y = i / cw
        for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] { let nx = x + dx, ny = y + dy; if nx >= 0, ny >= 0, nx < cw, ny < ch { let j = ny * cw + nx; if alpha[j] > 0 && lab[j] < 0 { lab[j] = id; q.append(j) } } } }
      if n > bestN { bestN = n; best = Int(id) }; id += 1
    }
    for i in 0..<(cw * ch) where alpha[i] > 0 && Int(lab[i]) != best { alpha[i] = 0 }
  }
  // 가장자리 부드럽게: 배경 옆 밝은 픽셀은 반투명
  var minX = cw, minY = ch, maxX = -1, maxY = -1
  for y in 0..<ch { for x in 0..<cw where alpha[y * cw + x] > 0 {
    var nearBg = false
    for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] { let nx = x + dx, ny = y + dy; if nx >= 0, ny >= 0, nx < cw, ny < ch, alpha[ny * cw + nx] == 0 { nearBg = true } }
    if nearBg && isBg(x0 + x, y0 + y, 140) { alpha[y * cw + x] = 110 }
    minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
  } }
  if maxX < 0 { print("empty cell", k); continue }
  if ProcessInfo.processInfo.environment["FIXED"] == "1" { minX = 0; minY = 0; maxX = cw - 1; maxY = ch - 1 } // 칸 전체를 같은 크기로 (애니메이션 프레임 위치 맞춤)
  // 잘라낸 그림(가장 긴 변 기준으로 정사각형 + 여백 6%)
  let bw = maxX - minX + 1, bh = maxY - minY + 1
  let panel = ProcessInfo.processInfo.environment["PANEL"] == "1"
  let side = panel ? max(bw, bh) : Int(Double(max(bw, bh)) * 1.12)
  var cell = [UInt8](repeating: 0, count: side * side * 4)
  let ox = (side - bw) / 2, oy = (side - bh) / 2
  for y in 0..<bh { for x in 0..<bw {
    let a8 = alpha[(minY + y) * cw + minX + x]; if a8 == 0 { continue }
    let si = ((y0 + minY + y) * W + x0 + minX + x) * 4, di = ((oy + y) * side + ox + x) * 4
    let f = Double(a8) / 255
    cell[di] = UInt8(Double(px[si]) * f); cell[di + 1] = UInt8(Double(px[si + 1]) * f); cell[di + 2] = UInt8(Double(px[si + 2]) * f); cell[di + 3] = a8
  } }
  let cctx = CGContext(data: &cell, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4, space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  let cut = cctx.makeImage()!
  let oh = panel ? size * bh / bw : size
  let octx = CGContext(data: nil, width: size, height: oh, bitsPerComponent: 8, bytesPerRow: size * 4, space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  octx.interpolationQuality = .high
  if panel { // 정사각형 판에서 그림 부분만 잘라 원래 비율로
    let crop = cut.cropping(to: CGRect(x: ox, y: side - oy - bh, width: bw, height: bh))!
    octx.draw(crop, in: CGRect(x: 0, y: 0, width: size, height: oh))
  } else { octx.draw(cut, in: CGRect(x: 0, y: 0, width: size, height: size)) }
  let out = URL(fileURLWithPath: "\(outDir)/\(names[k]).png")
  let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil)!
  CGImageDestinationAddImage(dest, octx.makeImage()!, nil); CGImageDestinationFinalize(dest)
  print("ok", names[k], "\(bw)x\(bh)")
} }
