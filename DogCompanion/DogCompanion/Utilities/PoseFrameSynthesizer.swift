import UIKit

enum PoseFrameSynthesizer {
    static func runA(from sitData: Data) -> Data? {
        runCycle(from: sitData)[safe: 0]
    }

    static func runB(from sitData: Data) -> Data? {
        runCycle(from: sitData)[safe: 1]
    }

    static func runC(from sitData: Data) -> Data? {
        runCycle(from: sitData)[safe: 2]
    }

    static func runD(from sitData: Data) -> Data? {
        runCycle(from: sitData)[safe: 3]
    }

    static func runCycle(from sitData: Data) -> [Data] {
        guard let image = UIImage(data: sitData) else { return [] }
        guard let pieces = slicedPieces(from: image) else { return [] }

        let poses: [LimbPose] = [
            LimbPose(leftX: 0.16, leftY: 0.11, leftRot: 24, leftStretch: 1.22,
                     rightX: -0.14, rightY: -0.05, rightRot: -20, rightStretch: 0.78,
                     torsoRot: -9, torsoY: -0.02, torsoX: 0.04),
            LimbPose(leftX: 0.05, leftY: -0.07, leftRot: 10, leftStretch: 0.88,
                     rightX: 0.05, rightY: -0.07, rightRot: -10, rightStretch: 0.88,
                     torsoRot: -13, torsoY: -0.09, torsoX: 0.05),
            LimbPose(leftX: -0.14, leftY: -0.05, leftRot: -20, leftStretch: 0.78,
                     rightX: 0.16, rightY: 0.11, rightRot: 24, rightStretch: 1.22,
                     torsoRot: -9, torsoY: -0.02, torsoX: 0.04),
            LimbPose(leftX: -0.04, leftY: 0.03, leftRot: -8, leftStretch: 1.08,
                     rightX: -0.04, rightY: 0.03, rightRot: 8, rightStretch: 1.08,
                     torsoRot: -7, torsoY: 0.01, torsoX: 0.03)
        ]

        return poses.compactMap { render(pieces: pieces, pose: $0) }
    }

    static func opaqueContentRect(of image: UIImage) -> CGRect? {
        guard let cgImage = image.cgImage else { return nil }
        return opaqueBounds(of: cgImage)
    }

    static func contentHeightScale(sitImage: UIImage, frameImage: UIImage) -> CGFloat {
        guard
            let sitBounds = opaqueContentRect(of: sitImage),
            let frameBounds = opaqueContentRect(of: frameImage),
            sitImage.size.height > 1,
            frameImage.size.height > 1
        else {
            return 1
        }
        let sitFraction = sitBounds.height / sitImage.size.height
        let frameFraction = frameBounds.height / frameImage.size.height
        guard frameFraction > 0.02 else { return 1 }
        return sitFraction / frameFraction
    }

    static func land(from sitData: Data) -> Data? {
        guard let image = UIImage(data: sitData) else { return nil }
        guard let pieces = slicedPieces(from: image) else { return nil }
        return render(
            pieces: pieces,
            pose: LimbPose(
                leftX: -0.09, leftY: 0.08, leftRot: -10, leftStretch: 0.84,
                rightX: 0.09, rightY: 0.08, rightRot: 10, rightStretch: 0.84,
                torsoRot: 5, torsoY: 0.06, torsoX: 0
            )
        )
    }

    static func looksLikeSamePose(_ lhs: Data, _ rhs: Data) -> Bool {
        guard let a = downsampleGray(lhs), let b = downsampleGray(rhs), a.count == b.count else {
            return true
        }
        var total = 0
        var counted = 0
        for index in a.indices {
            let av = a[index]
            let bv = b[index]
            if av.a < 12, bv.a < 12 { continue }
            total += abs(Int(av.g) - Int(bv.g))
            counted += 1
        }
        guard counted > 8 else { return true }
        return total / counted < 16
    }

    private struct LimbPose {
        var leftX: CGFloat
        var leftY: CGFloat
        var leftRot: CGFloat
        var leftStretch: CGFloat
        var rightX: CGFloat
        var rightY: CGFloat
        var rightRot: CGFloat
        var rightStretch: CGFloat
        var torsoRot: CGFloat
        var torsoY: CGFloat
        var torsoX: CGFloat
    }

    private struct Pieces {
        var width: CGFloat
        var height: CGFloat
        var torso: CGImage
        var torsoRect: CGRect
        var left: CGImage
        var leftRect: CGRect
        var right: CGImage
        var rightRect: CGRect
    }

    private struct GrayPixel {
        var g: UInt8
        var a: UInt8
    }

    private static func slicedPieces(from image: UIImage) -> Pieces? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        guard let bounds = opaqueBounds(of: cgImage), bounds.width > 4, bounds.height > 4 else {
            return nil
        }

        let torsoRect = CGRect(
            x: bounds.minX,
            y: bounds.minY,
            width: bounds.width,
            height: max(CGFloat(4), bounds.height * CGFloat(0.58))
        )
        let limbTop = bounds.minY + bounds.height * CGFloat(0.48)
        let limbHeight = bounds.maxY - limbTop
        let overlap = bounds.width * CGFloat(0.08)
        let mid = bounds.midX
        let leftRect = CGRect(
            x: bounds.minX,
            y: limbTop,
            width: mid - bounds.minX + overlap,
            height: limbHeight
        )
        let rightRect = CGRect(
            x: mid - overlap,
            y: limbTop,
            width: bounds.maxX - (mid - overlap),
            height: limbHeight
        )

        let pixelSize = CGSize(width: width, height: height)
        guard
            let torso = crop(image, to: torsoRect, pixelSize: pixelSize),
            let left = crop(image, to: leftRect, pixelSize: pixelSize),
            let right = crop(image, to: rightRect, pixelSize: pixelSize)
        else {
            return nil
        }

        return Pieces(
            width: CGFloat(width),
            height: CGFloat(height),
            torso: torso,
            torsoRect: torsoRect,
            left: left,
            leftRect: leftRect,
            right: right,
            rightRect: rightRect
        )
    }

    private static func render(pieces: Pieces, pose: LimbPose) -> Data? {
        // Keep the same canvas as the sit cutout so run-in matches seated size.
        let canvas = CGSize(width: pieces.width, height: pieces.height)
        let origin = CGPoint.zero
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: canvas, format: format)
        let rendered = renderer.image { context in
            let backIsLeft = pose.leftX <= pose.rightX
            if backIsLeft {
                draw(pieces.left, rect: pieces.leftRect, origin: origin, dx: pose.leftX, dy: pose.leftY, rotation: pose.leftRot, stretchY: pose.leftStretch, width: pieces.width, height: pieces.height, in: context)
            } else {
                draw(pieces.right, rect: pieces.rightRect, origin: origin, dx: pose.rightX, dy: pose.rightY, rotation: pose.rightRot, stretchY: pose.rightStretch, width: pieces.width, height: pieces.height, in: context)
            }
            draw(pieces.torso, rect: pieces.torsoRect, origin: origin, dx: pose.torsoX, dy: pose.torsoY, rotation: pose.torsoRot, stretchY: 1, width: pieces.width, height: pieces.height, in: context)
            if backIsLeft {
                draw(pieces.right, rect: pieces.rightRect, origin: origin, dx: pose.rightX, dy: pose.rightY, rotation: pose.rightRot, stretchY: pose.rightStretch, width: pieces.width, height: pieces.height, in: context)
            } else {
                draw(pieces.left, rect: pieces.leftRect, origin: origin, dx: pose.leftX, dy: pose.leftY, rotation: pose.leftRot, stretchY: pose.leftStretch, width: pieces.width, height: pieces.height, in: context)
            }
        }
        return rendered.pngData()
    }

    private static func draw(
        _ piece: CGImage,
        rect: CGRect,
        origin: CGPoint,
        dx: CGFloat,
        dy: CGFloat,
        rotation: CGFloat,
        stretchY: CGFloat,
        width: CGFloat,
        height: CGFloat,
        in context: UIGraphicsImageRendererContext
    ) {
        let center = CGPoint(
            x: origin.x + rect.midX + dx * width,
            y: origin.y + rect.midY + dy * height
        )
        let cg = context.cgContext
        cg.saveGState()
        cg.translateBy(x: center.x, y: center.y)
        cg.rotate(by: rotation * CGFloat.pi / CGFloat(180))
        cg.scaleBy(x: 1, y: stretchY)
        UIImage(cgImage: piece).draw(
            in: CGRect(
                x: -rect.width / 2,
                y: -rect.height / 2,
                width: rect.width,
                height: rect.height
            )
        )
        cg.restoreGState()
    }

    private static func crop(_ image: UIImage, to rect: CGRect, pixelSize: CGSize) -> CGImage? {
        let size = CGSize(width: max(CGFloat(1), rect.width), height: max(CGFloat(1), rect.height))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let cropped = renderer.image { _ in
            image.draw(
                in: CGRect(
                    x: -rect.minX,
                    y: -rect.minY,
                    width: pixelSize.width,
                    height: pixelSize.height
                )
            )
        }
        return cropped.cgImage
    }

    private static func opaqueBounds(of image: CGImage) -> CGRect? {
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let ok = pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return false
            }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard ok else { return nil }

        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0
        for y in 0..<height {
            for x in 0..<width {
                let alpha = pixels[(y * width + x) * 4 + 3]
                if alpha > 18 {
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }
        guard maxX > minX, maxY > minY else { return nil }
        return CGRect(
            x: CGFloat(minX),
            y: CGFloat(minY),
            width: CGFloat(maxX - minX + 1),
            height: CGFloat(maxY - minY + 1)
        )
    }

    private static func downsampleGray(_ data: Data) -> [GrayPixel]? {
        guard let image = UIImage(data: data) else { return nil }
        let size = CGSize(width: 16, height: 16)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let scaled = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let cgImage = scaled.cgImage else { return nil }
        var pixels = [UInt8](repeating: 0, count: 16 * 16 * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let ok = pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: 16,
                height: 16,
                bitsPerComponent: 8,
                bytesPerRow: 64,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return false
            }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: 16, height: 16))
            return true
        }
        guard ok else { return nil }
        var gray: [GrayPixel] = []
        gray.reserveCapacity(256)
        for index in 0..<256 {
            let base = index * 4
            let r = Int(pixels[base])
            let g = Int(pixels[base + 1])
            let b = Int(pixels[base + 2])
            gray.append(GrayPixel(g: UInt8((r + g + b) / 3), a: pixels[base + 3]))
        }
        return gray
    }
}

extension PoseCutoutSet {
    /// Stored run poses, or frames synthesized from the sit cutout so run-in matches the owner dog.
    func runFrameImages() -> [UIImage] {
        var images: [UIImage] = []
        for data in [runA, runB, runC, runD] {
            guard let data, let image = UIImage(data: data) else { continue }
            images.append(image)
        }
        if images.count >= 2 { return images }
        if let sit {
            let synthesized = PoseFrameSynthesizer.runCycle(from: sit)
            let synthImages = synthesized.compactMap { UIImage(data: $0) }
            if !synthImages.isEmpty { return synthImages }
        }
        return images
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
