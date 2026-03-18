import AppKit

let canvasSize = 1024
let outputPath = "assets/app_logo.png"

extension NSColor {
  convenience init(hex: Int, alpha: CGFloat = 1.0) {
    self.init(
      calibratedRed: CGFloat((hex >> 16) & 0xff) / 255.0,
      green: CGFloat((hex >> 8) & 0xff) / 255.0,
      blue: CGFloat(hex & 0xff) / 255.0,
      alpha: alpha
    )
  }
}

func polygon(center: CGPoint, radius: CGFloat, points: Int, rotation: CGFloat = 0) -> NSBezierPath {
  let path = NSBezierPath()
  for index in 0..<points {
    let angle = rotation + (CGFloat(index) * (.pi * 2.0 / CGFloat(points)))
    let point = CGPoint(
      x: center.x + cos(angle) * radius,
      y: center.y + sin(angle) * radius
    )
    if index == 0 {
      path.move(to: point)
    } else {
      path.line(to: point)
    }
  }
  path.close()
  return path
}

func fillCircle(center: CGPoint, radius: CGFloat, color: NSColor) {
  color.setFill()
  NSBezierPath(ovalIn: CGRect(
    x: center.x - radius,
    y: center.y - radius,
    width: radius * 2,
    height: radius * 2
  )).fill()
}

guard let bitmap = NSBitmapImageRep(
  bitmapDataPlanes: nil,
  pixelsWide: canvasSize,
  pixelsHigh: canvasSize,
  bitsPerSample: 8,
  samplesPerPixel: 4,
  hasAlpha: true,
  isPlanar: false,
  colorSpaceName: .deviceRGB,
  bytesPerRow: 0,
  bitsPerPixel: 0
) else {
  fatalError("Failed to create bitmap image rep.")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

guard let context = NSGraphicsContext.current?.cgContext else {
  fatalError("Failed to create graphics context.")
}

let backgroundRect = CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize)
let backgroundPath = NSBezierPath(
  roundedRect: backgroundRect,
  xRadius: 236,
  yRadius: 236
)
NSColor(hex: 0x103C39).setFill()
backgroundPath.fill()

let gradient = CGGradient(
  colorsSpace: CGColorSpaceCreateDeviceRGB(),
  colors: [
    NSColor(hex: 0x1A6F66, alpha: 0.95).cgColor,
    NSColor(hex: 0x103C39, alpha: 0.0).cgColor,
  ] as CFArray,
  locations: [0.0, 1.0]
)!
context.drawRadialGradient(
  gradient,
  startCenter: CGPoint(x: 340, y: 780),
  startRadius: 10,
  endCenter: CGPoint(x: 340, y: 780),
  endRadius: 520,
  options: [.drawsAfterEndLocation]
)

fillCircle(center: CGPoint(x: 512, y: 512), radius: 360, color: NSColor(hex: 0xF6EDD6, alpha: 0.08))
fillCircle(center: CGPoint(x: 512, y: 512), radius: 292, color: NSColor(hex: 0xF6EDD6, alpha: 0.16))

let archOuter = NSBezierPath()
archOuter.move(to: CGPoint(x: 250, y: 245))
archOuter.line(to: CGPoint(x: 250, y: 565))
archOuter.curve(
  to: CGPoint(x: 512, y: 845),
  controlPoint1: CGPoint(x: 250, y: 730),
  controlPoint2: CGPoint(x: 390, y: 845)
)
archOuter.curve(
  to: CGPoint(x: 774, y: 565),
  controlPoint1: CGPoint(x: 634, y: 845),
  controlPoint2: CGPoint(x: 774, y: 730)
)
archOuter.line(to: CGPoint(x: 774, y: 245))
archOuter.close()
NSColor(hex: 0xF4E6BE).setFill()
archOuter.fill()

let archInner = NSBezierPath()
archInner.move(to: CGPoint(x: 308, y: 290))
archInner.line(to: CGPoint(x: 308, y: 545))
archInner.curve(
  to: CGPoint(x: 512, y: 770),
  controlPoint1: CGPoint(x: 308, y: 675),
  controlPoint2: CGPoint(x: 418, y: 770)
)
archInner.curve(
  to: CGPoint(x: 716, y: 545),
  controlPoint1: CGPoint(x: 606, y: 770),
  controlPoint2: CGPoint(x: 716, y: 675)
)
archInner.line(to: CGPoint(x: 716, y: 290))
archInner.close()
NSColor(hex: 0x174C47).setFill()
archInner.fill()

let starBack = polygon(center: CGPoint(x: 512, y: 720), radius: 56, points: 8, rotation: .pi / 8)
NSColor(hex: 0xD6A84C).setFill()
starBack.fill()

let starFront = polygon(center: CGPoint(x: 512, y: 720), radius: 24, points: 8, rotation: 0)
NSColor(hex: 0xF8F2E2).setFill()
starFront.fill()

let leftPage = NSBezierPath()
leftPage.move(to: CGPoint(x: 318, y: 365))
leftPage.curve(
  to: CGPoint(x: 486, y: 405),
  controlPoint1: CGPoint(x: 350, y: 462),
  controlPoint2: CGPoint(x: 420, y: 446)
)
leftPage.line(to: CGPoint(x: 486, y: 645))
leftPage.curve(
  to: CGPoint(x: 318, y: 610),
  controlPoint1: CGPoint(x: 424, y: 616),
  controlPoint2: CGPoint(x: 360, y: 628)
)
leftPage.close()
NSColor(hex: 0xF8F1DD).setFill()
leftPage.fill()

let rightPage = NSBezierPath()
rightPage.move(to: CGPoint(x: 706, y: 365))
rightPage.curve(
  to: CGPoint(x: 538, y: 405),
  controlPoint1: CGPoint(x: 674, y: 462),
  controlPoint2: CGPoint(x: 604, y: 446)
)
rightPage.line(to: CGPoint(x: 538, y: 645))
rightPage.curve(
  to: CGPoint(x: 706, y: 610),
  controlPoint1: CGPoint(x: 600, y: 616),
  controlPoint2: CGPoint(x: 664, y: 628)
)
rightPage.close()
NSColor(hex: 0xF8F1DD).setFill()
rightPage.fill()

let pageShadow = NSBezierPath()
pageShadow.move(to: CGPoint(x: 328, y: 365))
pageShadow.curve(
  to: CGPoint(x: 486, y: 405),
  controlPoint1: CGPoint(x: 356, y: 450),
  controlPoint2: CGPoint(x: 420, y: 442)
)
pageShadow.line(to: CGPoint(x: 486, y: 447))
pageShadow.curve(
  to: CGPoint(x: 336, y: 412),
  controlPoint1: CGPoint(x: 428, y: 421),
  controlPoint2: CGPoint(x: 375, y: 426)
)
pageShadow.close()
NSColor(hex: 0xD6A84C, alpha: 0.22).setFill()
pageShadow.fill()

let pageShadowRight = NSBezierPath()
pageShadowRight.move(to: CGPoint(x: 696, y: 365))
pageShadowRight.curve(
  to: CGPoint(x: 538, y: 405),
  controlPoint1: CGPoint(x: 668, y: 450),
  controlPoint2: CGPoint(x: 604, y: 442)
)
pageShadowRight.line(to: CGPoint(x: 538, y: 447))
pageShadowRight.curve(
  to: CGPoint(x: 688, y: 412),
  controlPoint1: CGPoint(x: 596, y: 421),
  controlPoint2: CGPoint(x: 649, y: 426)
)
pageShadowRight.close()
NSColor(hex: 0xD6A84C, alpha: 0.22).setFill()
pageShadowRight.fill()

let spine = NSBezierPath(roundedRect: CGRect(x: 497, y: 362, width: 30, height: 286), xRadius: 15, yRadius: 15)
NSColor(hex: 0xD6A84C).setFill()
spine.fill()

let base = NSBezierPath(roundedRect: CGRect(x: 292, y: 305, width: 440, height: 40), xRadius: 20, yRadius: 20)
NSColor(hex: 0xD6A84C).setFill()
base.fill()

let accent = NSBezierPath()
accent.move(to: CGPoint(x: 340, y: 235))
accent.curve(
  to: CGPoint(x: 684, y: 235),
  controlPoint1: CGPoint(x: 432, y: 198),
  controlPoint2: CGPoint(x: 592, y: 198)
)
accent.curve(
  to: CGPoint(x: 748, y: 265),
  controlPoint1: CGPoint(x: 708, y: 236),
  controlPoint2: CGPoint(x: 730, y: 248)
)
accent.line(to: CGPoint(x: 748, y: 289))
accent.line(to: CGPoint(x: 276, y: 289))
accent.line(to: CGPoint(x: 276, y: 265))
accent.curve(
  to: CGPoint(x: 340, y: 235),
  controlPoint1: CGPoint(x: 294, y: 248),
  controlPoint2: CGPoint(x: 316, y: 236)
)
accent.close()
NSColor(hex: 0xF4E6BE, alpha: 0.9).setFill()
accent.fill()

NSGraphicsContext.restoreGraphicsState()

let outputURL = URL(fileURLWithPath: outputPath)
let directoryURL = outputURL.deletingLastPathComponent()
try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

guard let data = bitmap.representation(using: .png, properties: [:]) else {
  fatalError("Failed to create PNG data.")
}

try data.write(to: outputURL)
print("Generated \(outputPath)")
