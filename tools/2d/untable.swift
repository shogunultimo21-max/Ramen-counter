// 그림 아래쪽에 깔린 탁자(한 가지 색 띠)를 지움: untable file... → 띠 색과 비슷한 픽셀을 투명하게 (띠 윗선 아래만)
import AppKit
import UniformTypeIdentifiers
for f in CommandLine.arguments.dropFirst() {
  let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: f) as CFURL, nil)!, img = CGImageSourceCreateImageAtIndex(src, 0, nil)!
  let W = img.width, H = img.height, cs = CGColorSpaceCreateDeviceRGB()
  var px = [UInt8](repeating: 0, count: W * H * 4)
  let ctx = CGContext(data: &px, width: W, height: H, bitsPerComponent: 8, bytesPerRow: W * 4, space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  ctx.draw(img, in: CGRect(x: 0, y: 0, width: W, height: H))
  // 띠 색: 왼쪽 가장자리 근처에서 아래에서 위로 올라가며 처음 만나는 불투명 픽셀들 (메모리는 위→아래 순)
  var top = -1, cr = 0, cg = 0, cb = 0, n = 0
  // 띠 색: 맨 아래 불투명 픽셀 근처 색 → 위로 올라가며 그 색이 이어지는 동안이 띠 (팔·손을 만나면 멈춤)
  let sx = W * 85 / 100
  var y0 = -1
  for y in stride(from: H - 1, through: 0, by: -1) where px[(y * W + sx) * 4 + 3] > 200 { y0 = y; break }
  if y0 >= 0 {
    func col(_ y: Int) -> (Int, Int, Int) { let i = (y * W + sx) * 4, a = max(1, Int(px[i + 3])); return (Int(px[i]) * 255 / a, Int(px[i + 1]) * 255 / a, Int(px[i + 2]) * 255 / a) }
    let base = col(max(0, y0 - 4))
    var y = y0
    while y > 0 { let c = col(y); if px[(y * W + sx) * 4 + 3] < 200 || abs(c.0 - base.0) + abs(c.1 - base.1) + abs(c.2 - base.2) > 70 { break }
      cr += c.0; cg += c.1; cb += c.2; n += 1; top = y; y -= 1 }
  }
  // TOP=숫자: 띠 윗선을 직접 지정 (띠 색은 그 아래 몇 줄에서)
  if let t = ProcessInfo.processInfo.environment["TOP"], let tv = Int(t) {
    top = tv; cr = 0; cg = 0; cb = 0; n = 0
    for y in (tv + 6)..<min(H, tv + 20) { for x in Array(stride(from: W * 3 / 100, to: W * 12 / 100, by: 2)) + Array(stride(from: W * 88 / 100, to: W * 97 / 100, by: 2)) { let i = (y * W + x) * 4, a = Int(px[i + 3]); if a > 200 { cr += Int(px[i]) * 255 / a; cg += Int(px[i + 1]) * 255 / a; cb += Int(px[i + 2]) * 255 / a; n += 1 } } }
  }
  guard n > 0 else { print("no band", f); continue }
  cr /= n; cg /= n; cb /= n
  var cleared = 0
  // FLOOD=1: 띠 색과 이어진 부분만 지움 (그릇·손처럼 띠 위에 놓인 건 남김)
  if ProcessInfo.processInfo.environment["FLOOD"] == "1" {
    let tol = Int(ProcessInfo.processInfo.environment["TOL"] ?? "40")!
    func near(_ i: Int) -> Bool { let a = Int(px[i + 3]); if a < 128 { return false }
      let r = Int(px[i]) * 255 / a, g = Int(px[i + 1]) * 255 / a, b = Int(px[i + 2]) * 255 / a
      return abs(r - cr) + abs(g - cg) + abs(b - cb) < tol }
    var seen = [Bool](repeating: false, count: W * H), st: [Int] = []
    for y in max(0, top - 1)..<H { st.append(y * W); st.append(y * W + W - 1) }
    for x in 0..<W { st.append((H - 1) * W + x) }
    while let p = st.popLast() { if seen[p] { continue }; seen[p] = true
      let y = p / W, x = p % W; if y < top - 1 { continue }
      let i = p * 4; if px[i + 3] == 0 { if y >= top { for q in [p - 1, p + 1, p - W, p + W] where q >= 0 && q < W * H && abs(q % W - x) <= 1 { st.append(q) } }; continue }
      if !near(i) { continue }
      px[i] = 0; px[i + 1] = 0; px[i + 2] = 0; px[i + 3] = 0; cleared += 1
      for q in [p - 1, p + 1, p - W, p + W] where q >= 0 && q < W * H && abs(q % W - x) <= 1 { st.append(q) }
    }
    // 띠 가장자리에 남은 반투명 테두리·선: 띠 윗선 아래에서 띠와 같은 줄의 얇은 잔여물 정리
    // 띠 윗선에서 26칸(게임 화면에서 앞 카운터에 가려지는 높이)보다 아래는 모두 지움
    let deep = top + Int(ProcessInfo.processInfo.environment["DEEP"] ?? "26")!
    for y in max(0, top - 1)..<H { for x in 0..<W { let i = (y * W + x) * 4; if y > deep || px[i + 3] > 0 && px[i + 3] < 200 { px[i] = 0; px[i + 1] = 0; px[i + 2] = 0; px[i + 3] = 0 } } }
  } else {
  for y in max(0, top - 1)..<H { for x in 0..<W { let i = (y * W + x) * 4; let a = Int(px[i + 3]); if a == 0 { continue }
    // 미리 곱해진 색 → 원래 색
    let r = Int(px[i]) * 255 / a, g = Int(px[i + 1]) * 255 / a, b = Int(px[i + 2]) * 255 / a
    if y > top + 1 || abs(r - cr) + abs(g - cg) + abs(b - cb) < 40 && y >= top - 1 { px[i] = 0; px[i + 1] = 0; px[i + 2] = 0; px[i + 3] = 0; cleared += 1 } } }
  }
  let out = CGContext(data: &px, width: W, height: H, bitsPerComponent: 8, bytesPerRow: W * 4, space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: f) as CFURL, UTType.png.identifier as CFString, 1, nil)!
  CGImageDestinationAddImage(d, out.makeImage()!, nil); CGImageDestinationFinalize(d)
  if f.hasSuffix("020.png") { print(f, "band top", top, Double(top) / Double(H), "color", cr, cg, cb, "cleared", cleared) }
}
