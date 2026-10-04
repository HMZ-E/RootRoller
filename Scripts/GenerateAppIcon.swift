import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// A code-drawn mark: five dice pips connected as a network. iOS applies the icon mask.
let edge = 1024
let context = CGContext(data: nil, width: edge, height: edge, bitsPerComponent: 8,
                        bytesPerRow: edge * 4, space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
let colors = [CGColor(red: 0.08, green: 0.48, blue: 1, alpha: 1),
              CGColor(red: 0.08, green: 0.24, blue: 0.82, alpha: 1)] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
context.drawLinearGradient(gradient, start: CGPoint(x: 150, y: 1024), end: CGPoint(x: 860, y: 0), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
context.setFillColor(CGColor(gray: 1, alpha: 0.06))
context.fillEllipse(in: CGRect(x: 420, y: 490, width: 1000, height: 1000))
context.setStrokeColor(CGColor(gray: 1, alpha: 0.95))
context.setLineWidth(28)
context.addPath(CGPath(roundedRect: CGRect(x: 214, y: 214, width: 596, height: 596), cornerWidth: 132, cornerHeight: 132, transform: nil))
context.strokePath()
let center = CGPoint(x: 512, y: 512)
let corners = [CGPoint(x: 352, y: 352), CGPoint(x: 672, y: 352), CGPoint(x: 352, y: 672), CGPoint(x: 672, y: 672)]
context.setLineWidth(24)
context.setLineCap(.round)
context.setStrokeColor(CGColor(gray: 1, alpha: 0.65))
for corner in corners {
    let path = CGMutablePath()
    path.addLines(between: [center, corner])
    context.addPath(path)
    context.strokePath()
}
context.setFillColor(CGColor(gray: 1, alpha: 1))
for point in corners + [center] {
    let radius: CGFloat = point == center ? 50 : 40
    context.fillEllipse(in: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
}
let output = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "RootRoller/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, context.makeImage()!, nil)
precondition(CGImageDestinationFinalize(destination))
print("Wrote 1024px opaque app icon: \(output.path)")
