import UIKit

enum CompanionPart: String, CaseIterable {
    case tail
    case backLeg
    case body
    case frontLeg
    case head
}

struct CompanionLayerSet {
    var canvasSize: CGSize
    var scale: CGFloat
    var images: [CompanionPart: UIImage]
    var tailOnLeft: Bool

    func image(for part: CompanionPart) -> UIImage? {
        images[part]
    }
}

/// Splits one sit cutout into overlapping PNG layers so SpriteKit can move
/// head / body / legs / tail independently, like a paper puppet.
enum CompanionLayerSlicer {
    private struct RGBA {
        var r: UInt8
        var g: UInt8
        var b: UInt8
        var a: UInt8
    }

    static func slice(_ image: UIImage) -> CompanionLayerSet? {
        guard let pixels = rgbaPixels(from: image),
              let cgImage = image.cgImage else {
            return nil
        }

        let width = cgImage.width
        let height = cgImage.height
        guard width > 4, height > 4, pixels.count == width * height else {
            return nil
        }
        guard let bounds = opaqueBounds(pixels: pixels, width: width, height: height) else {
            return nil
        }

        let tailOnLeft = tailIsOnLeft(pixels: pixels, width: width, bounds: bounds)
        let spanX = max(1, bounds.maxX - bounds.minX)
        let spanY = max(1, bounds.maxY - bounds.minY)
        let parts = CompanionPart.allCases
        var partBuffers: [CompanionPart: [UInt8]] = Dictionary(
            uniqueKeysWithValues: parts.map { ($0, [UInt8](repeating: 0, count: width * height * 4)) }
        )

        for y in 0..<height {
            for x in 0..<width {
                let pixel = pixels[y * width + x]
                guard pixel.a >= 12 else { continue }

                let nx = Float(x - bounds.minX) / Float(spanX)
                let ny = Float(y - bounds.minY) / Float(spanY)
                let winner = winningPart(
                    nx: nx,
                    ny: ny,
                    tailOnLeft: tailOnLeft
                )
                let solid = solidPixel(pixel)
                let offset = (y * width + x) * 4
                var buffer = partBuffers[winner]!
                buffer[offset] = solid.r
                buffer[offset + 1] = solid.g
                buffer[offset + 2] = solid.b
                buffer[offset + 3] = solid.a
                partBuffers[winner] = buffer
            }
        }

        var images: [CompanionPart: UIImage] = [:]
        for part in parts {
            guard let buffer = partBuffers[part],
                  opaqueCount(in: buffer) > 8,
                  let png = image(from: buffer, width: width, height: height, scale: image.scale) else {
                continue
            }
            images[part] = png
        }
        guard images[.head] != nil || images[.body] != nil else {
            return nil
        }

        return CompanionLayerSet(
            canvasSize: CGSize(width: CGFloat(width) / image.scale, height: CGFloat(height) / image.scale),
            scale: image.scale,
            images: images,
            tailOnLeft: tailOnLeft
        )
    }

    private static func winningPart(nx: Float, ny: Float, tailOnLeft: Bool) -> CompanionPart {
        var bestPart = CompanionPart.body
        var bestWeight: Float = -1
        for part in CompanionPart.allCases {
            let value = weight(for: part, nx: nx, ny: ny, tailOnLeft: tailOnLeft)
            if value > bestWeight {
                bestWeight = value
                bestPart = part
            }
        }
        return bestPart
    }

    private static func solidPixel(_ pixel: RGBA) -> RGBA {
        guard pixel.a >= 12 else {
            return RGBA(r: 0, g: 0, b: 0, a: 0)
        }
        var solid = pixel
        if solid.a < 255 {
            let alpha = Double(solid.a)
            solid.r = UInt8(clamping: Int((Double(solid.r) * 255.0 / alpha).rounded()))
            solid.g = UInt8(clamping: Int((Double(solid.g) * 255.0 / alpha).rounded()))
            solid.b = UInt8(clamping: Int((Double(solid.b) * 255.0 / alpha).rounded()))
        }
        solid.a = 255
        return solid
    }

    private static func opaqueCount(in buffer: [UInt8]) -> Int {
        var count = 0
        for offset in stride(from: 3, to: buffer.count, by: 4) where buffer[offset] > 200 {
            count += 1
        }
        return count
    }

    static func weight(
        for part: CompanionPart,
        nx: Float,
        ny: Float,
        tailOnLeft: Bool
    ) -> Float {
        let head = headWeight(nx: nx, ny: ny)
        let frontLeg = frontLegWeight(nx: nx, ny: ny)
        let backLeg = backLegWeight(nx: nx, ny: ny)
        let tail = tailWeight(nx: nx, ny: ny, tailOnLeft: tailOnLeft)
        switch part {
        case .head:
            return head
        case .frontLeg:
            return frontLeg
        case .backLeg:
            return backLeg
        case .tail:
            return tail
        case .body:
            // Moving parts stay off the torso copy, or wag/run shows a second frozen tail or legs.
            // Keep a little joint overlap so rotation does not open a hole at the hip or neck.
            let torso = band(ny, 0.36, 0.46, 0.80, 0.92) * band(nx, -0.04, 0.02, 0.98, 1.04)
            let legs = min(1.0, frontLeg + backLeg)
            return torso * (1.0 - head) * (1.0 - tail) * (1.0 - legs * 0.80)
        }
    }

    private static func headWeight(nx: Float, ny: Float) -> Float {
        // Full width so ears and ruff are not shaved off the sit cutout.
        band(ny, -0.02, 0.0, 0.40, 0.52) * band(nx, -0.08, 0.0, 1.0, 1.08)
    }

    private static func frontLegWeight(nx: Float, ny: Float) -> Float {
        band(ny, 0.70, 0.80, 0.99, 1.06) * band(nx, 0.28, 0.38, 0.62, 0.72)
    }

    private static func backLegWeight(nx: Float, ny: Float) -> Float {
        let vertical = band(ny, 0.68, 0.78, 0.99, 1.06)
        let left = band(nx, 0.0, 0.04, 0.26, 0.38)
        let right = band(nx, 0.62, 0.74, 0.96, 1.0)
        return min(1.0, vertical * (left + right))
    }

    private static func tailWeight(nx: Float, ny: Float, tailOnLeft: Bool) -> Float {
        // Narrower than the rump so the wagging layer is one tail, not a second hip.
        let vertical = band(ny, 0.42, 0.54, 0.88, 0.99)
        if tailOnLeft {
            return vertical * band(nx, -0.02, 0.0, 0.16, 0.28)
        }
        return vertical * band(nx, 0.72, 0.84, 1.0, 1.02)
    }

    private static func tailIsOnLeft(
        pixels: [RGBA],
        width: Int,
        bounds: (minX: Int, minY: Int, maxX: Int, maxY: Int)
    ) -> Bool {
        let spanX = max(1, bounds.maxX - bounds.minX)
        let spanY = max(1, bounds.maxY - bounds.minY)
        var left = 0
        var right = 0
        let y0 = bounds.minY + spanY * 2 / 5
        let y1 = bounds.minY + spanY * 9 / 10
        for y in y0..<y1 {
            for x in bounds.minX...bounds.maxX {
                if pixels[y * width + x].a < 18 {
                    continue
                }
                let nx = Float(x - bounds.minX) / Float(spanX)
                if nx < 0.32 {
                    left += 1
                } else if nx > 0.68 {
                    right += 1
                }
            }
        }
        return left >= right
    }

    private static func opaqueBounds(
        pixels: [RGBA],
        width: Int,
        height: Int
    ) -> (minX: Int, minY: Int, maxX: Int, maxY: Int)? {
        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0
        for y in 0..<height {
            for x in 0..<width {
                if pixels[y * width + x].a > 18 {
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }
        guard maxX > minX, maxY > minY else { return nil }
        return (minX, minY, maxX, maxY)
    }

    private static func band(_ value: Float, _ a: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
        smoothstep(a, b, value) * (1.0 - smoothstep(c, d, value))
    }

    private static func smoothstep(_ edge0: Float, _ edge1: Float, _ x: Float) -> Float {
        let span = edge1 - edge0
        guard span != 0 else { return x >= edge1 ? 1 : 0 }
        let t = min(1.0, max(0.0, (x - edge0) / span))
        return t * t * (3.0 - 2.0 * t)
    }

    private static func rgbaPixels(from image: UIImage) -> [RGBA]? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = 4 * width
        var pixelData = [UInt8](repeating: 0, count: height * bytesPerRow)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return nil
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var pixels: [RGBA] = []
        pixels.reserveCapacity(width * height)
        for index in stride(from: 0, to: pixelData.count, by: 4) {
            pixels.append(
                RGBA(
                    r: pixelData[index],
                    g: pixelData[index + 1],
                    b: pixelData[index + 2],
                    a: pixelData[index + 3]
                )
            )
        }
        return pixels
    }

    private static func image(from pixelData: [UInt8], width: Int, height: Int, scale: CGFloat) -> UIImage? {
        var data = pixelData
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        guard let context = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 4 * width,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ), let cgImage = context.makeImage() else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }
}
