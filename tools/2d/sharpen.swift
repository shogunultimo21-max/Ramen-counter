// 흐릿한 손님 그림 묶음(JPEG)을 선명하게: sharpen in.jpg out.jpg [radius] [intensity]
import AppKit
import CoreImage
let a = CommandLine.arguments
let radius = a.count > 3 ? Double(a[3])! : 1.6, amount = a.count > 4 ? Double(a[4])! : 0.7
let input = CIImage(contentsOf: URL(fileURLWithPath: a[1]))!
let f = CIFilter(name: "CIUnsharpMask")!
f.setValue(input, forKey: kCIInputImageKey); f.setValue(radius, forKey: kCIInputRadiusKey); f.setValue(amount, forKey: kCIInputIntensityKey)
let out = f.outputImage!.cropped(to: input.extent)
let ctx = CIContext()
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
try! ctx.writeJPEGRepresentation(of: out, to: URL(fileURLWithPath: a[2]), colorSpace: cs, options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.82])
print("ok", a[2])
