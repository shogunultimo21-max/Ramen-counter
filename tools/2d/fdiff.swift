// 프레임 사이 차이: fdiff dir N → 각 프레임 i와 0..9번 프레임의 차이(작을수록 비슷)
import AppKit
let dir = CommandLine.arguments[1], N = Int(CommandLine.arguments[2])!
func load(_ i: Int) -> [Float] {
  let img = NSImage(contentsOfFile: String(format: "%@/f%03d.png", dir, i))!
  let w = 64; let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: w, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: w * 4, bitsPerPixel: 32)!
  NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
  img.draw(in: NSRect(x: 0, y: 0, width: w, height: w)); NSGraphicsContext.restoreGraphicsState()
  let p = rep.bitmapData!; return (0..<(w * w * 4)).map { Float(p[$0]) }
}
let F = (0..<N).map(load)
func d(_ a: Int, _ b: Int) -> Float { zip(F[a], F[b]).reduce(0) { $0 + abs($1.0 - $1.1) } / Float(F[a].count) }
var best: (Float, Int, Int) = (1e9, 0, 0)
for s in 0..<10 { for e in (N - 25)..<N { let v = d(s, e); if v < best.0 { best = (v, s, e) } } }
print("가장 비슷: 시작", best.1, "끝", best.2, "차이", best.0)
print("참고: 인접 프레임 평균 차이", (1..<N).map { d($0 - 1, $0) }.reduce(0, +) / Float(N - 1), "/ 0↔마지막", d(0, N - 1))
