// 영상 → PNG 프레임: frames in.mp4 outDir fps size
import Foundation
import AVFoundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
let a = CommandLine.arguments
let asset = AVURLAsset(url: URL(fileURLWithPath: a[1]))
let out = a[2], fps = Double(a[3])!, size = Int(a[4])!
try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
let gen = AVAssetImageGenerator(asset: asset)
gen.requestedTimeToleranceBefore = .zero; gen.requestedTimeToleranceAfter = .zero
gen.maximumSize = CGSize(width: size, height: size)
let dur = CMTimeGetSeconds(asset.duration)
var t = 0.0, k = 0
while t < dur - 0.01 {
  if let img = try? gen.copyCGImage(at: CMTime(seconds: t, preferredTimescale: 600), actualTime: nil) {
    let u = URL(fileURLWithPath: String(format: "%@/f%03d.png", out, k))
    let d = CGImageDestinationCreateWithURL(u as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(d, img, nil); CGImageDestinationFinalize(d); k += 1
  }
  t += 1 / fps
}
print("frames", k, "dur", dur)
