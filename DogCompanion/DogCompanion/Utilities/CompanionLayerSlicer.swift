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
        var images: [CompanionPart: UIImage] = [:]
        for part in CompanionPart.allCases {
            if let png = render(
                pixels: pixels,
                width: width,
                height: height,
                scale: image.scale,
                weight: { nx, ny in
                    weight(for: part, nx: nx, ny: ny, tailOnLeft: tailOnLeft)
                },
                bounds: bounds
            ) {
                images[part] = png
            }
        }
        guard images[.head] != nil || images[.body] != nil else {
            return nil
        }

        return CompanionLayerSet(
            canvasSize: CGSize(width: CGFloat(width) / image.scale, height: CGFloat(height) / image.scale),
            scale: image.scale,
            images: images
        )
    }

    static func weight(
        for part: CompanionPart,
        nx: Float,
        ny: Float,
        tailOnLeft: Bool
    ) -> Float {
        switch part {
        case .head:
            return band(ny, -0.02, 0.0, 0.34, 0.50) * band(nx, 0.10, 0.20, 0.80, 0.90)
        case .body:
            return band(ny, 0.20, 0.34, 0.72, 0.90) * band(nx, 0.06, 0.16, 0.84, 0.94)
        case .frontLeg:
            return band(ny, 0.56, 0.68, 0.96, 1.05) * band(nx, 0.26, 0.36, 0.64, 0.74)
        case .backLeg:
            let vertical = band(ny, 0.52, 0.64, 0.98, 1.05)
            let left = band(nx, 0.0, 0.04, 0.28, 0.40)
            let right = band(nx, 0.60, 0.72, 0.96, 1.0)
            return min(1.0, vertical * (left + right))
        case .tail:
            let vertical = band(ny, 0.38, 0.50, 0.86, 0.98)
            if tailOnLeft {
                return vertical * band(nx, 0.0, 0.0, 0.22, 0.38)
            }
            return vertical * band(nx, 0.62, 0.78, 1.0, 1.0)
        }
    }

    private static func render(
        pixels: [RGBA],
        width: Int,
        height: Int,
        scale: CGFloat,
        weight: (Float, Float) -> Float,
        bounds: (minX: Int, minY: Int, maxX: Int, maxY: Int)
    ) -> UIImage? {
        let spanX = max(1, bounds.maxX - bounds.minX)
        let spanY = max(1, bounds.maxY - bounds.minY)
        var output = [UInt8](repeating: 0, count: width * height * 4)
        var opaque = 0

        for y in 0..<height {
            for x in 0..<width {
                let pixel = pixels[y * width + x]
                if pixel.a < 12 {
                    continue
                }
                let nx = Float(x - bounds.minX) / Float(spanX)
                let ny = Float(y - bounds.minY) / Float(spanY)
                let mask = weight(nx, ny)
                if mask < 0.02 {
                    continue
                }
                let factor = Double(mask)
                let offset = (y * width + x) * 4
                output[offset] = channel(pixel.r, factor)
                output[offset + 1] = channel(pixel.g, factor)
                output[offset + 2] = channel(pixel.b, factor)
                output[offset + 3] = channel(pixel.a, factor)
                opaque += 1
            }
        }

        guard opaque > 8 else { return nil }
        return image(from: output, width: width, height: height, scale: scale)
    }

    private static func channel(_ value: UInt8, _ factor: Double) -> UInt8 {
        let scaled = Double(value) * min(1.0, max(0.0, factor))
        return UInt8(min(255.0, max(0.0, scaled.rounded())))
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
