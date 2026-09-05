import UIKit
import Vision
import CoreImage
import CoreML
import ImageIO

enum MattingError: LocalizedError {
    case invalidImage
    case maskGenerationFailed
    case exportFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无法处理漫画图片。"
        case .maskGenerationFailed:
            return "抠图失败，请换一张照片重试。"
        case .exportFailed:
            return "无法导出透明底图片。"
        }
    }
}

enum CutoutImageProcessor {
    struct RGBA: Sendable {
        var r: UInt8
        var g: UInt8
        var b: UInt8
        var a: UInt8
    }

    static func hasMeaningfulTransparency(in data: Data, threshold: UInt8 = 16) -> Bool {
        guard let image = UIImage(data: data), let pixels = rgbaPixels(from: image) else {
            return false
        }
        let transparentCount = pixels.filter { $0.a < threshold }.count
        return transparentCount > pixels.count / 50
    }

    static func needsCutoutRefresh(_ data: Data?) -> Bool {
        guard let data,
              let image = UIImage(data: data),
              let cgImage = image.cgImage,
              let pixels = rgbaPixels(from: image) else {
            return true
        }

        if !hasMeaningfulTransparency(in: data) {
            return true
        }

        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return true }

        let opaqueCount = pixels.reduce(0) { $0 + ($1.a > 200 ? 1 : 0) }
        if opaqueCount < max(80, pixels.count / 20) {
            return true
        }

        if hasSemiTransparentForeground(pixels: pixels, width: width, height: height) {
            return true
        }

        if hasInteriorHoles(pixels: pixels, width: width, height: height) {
            return true
        }

        let cornerSamples = [
            pixels[0],
            pixels[width - 1],
            pixels[(height - 1) * width],
            pixels[height * width - 1]
        ]
        if cornerSamples.filter({ $0.a > 200 }).count >= 3 {
            return true
        }

        return false
    }

    /// Vision masks on device often leave light fur at alpha 20–200; treat as stale cutout.
    private static func hasSemiTransparentForeground(
        pixels: [RGBA],
        width: Int,
        height: Int
    ) -> Bool {
        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0
        for y in 0..<height {
            for x in 0..<width where pixels[y * width + x].a > 12 {
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }
        guard maxX > minX, maxY > minY else { return false }

        var foreground = 0
        var soft = 0
        for y in minY...maxY {
            for x in minX...maxX {
                let alpha = pixels[y * width + x].a
                guard alpha > 12 else { continue }
                foreground += 1
                if alpha < 245 {
                    soft += 1
                }
            }
        }
        guard foreground > 0 else { return false }
        return Double(soft) / Double(foreground) > 0.02
    }

    /// Vision often keeps the dark outline of a cream-colored dog and punches the body empty.
    static func hasInteriorHoles(in data: Data) -> Bool {
        guard let image = UIImage(data: data),
              let cgImage = image.cgImage,
              let pixels = rgbaPixels(from: image) else {
            return true
        }
        return hasInteriorHoles(pixels: pixels, width: cgImage.width, height: cgImage.height)
    }

    private static func hasInteriorHoles(
        pixels: [RGBA],
        width: Int,
        height: Int,
        holeRatio: Double = 0.12
    ) -> Bool {
        guard width > 0, height > 0, pixels.count == width * height else { return true }

        // Sitting dogs leave transparent gaps between legs/ears that still open to the
        // canvas edge. Only count voids that the border flood cannot reach.
        var reachableFromBorder = [Bool](repeating: false, count: pixels.count)
        var stack: [Int] = []
        stack.reserveCapacity(width * 2 + height * 2)

        for x in 0..<width {
            stack.append(x)
            stack.append((height - 1) * width + x)
        }
        for y in 1..<(height - 1) {
            stack.append(y * width)
            stack.append(y * width + width - 1)
        }

        while let current = stack.popLast() {
            if reachableFromBorder[current] { continue }
            if pixels[current].a >= 12 { continue }
            reachableFromBorder[current] = true
            let x = current % width
            let y = current / width
            if x > 0 { stack.append(current - 1) }
            if x + 1 < width { stack.append(current + 1) }
            if y > 0 { stack.append(current - width) }
            if y + 1 < height { stack.append(current + width) }
        }

        var opaque = 0
        var enclosed = 0
        for index in pixels.indices {
            if pixels[index].a > 18 {
                opaque += 1
            } else if !reachableFromBorder[index] {
                enclosed += 1
            }
        }
        guard opaque > 80 else { return false }
        if Double(enclosed) / Double(opaque) > holeRatio {
            return true
        }

        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0
        for y in 0..<height {
            for x in 0..<width where pixels[y * width + x].a > 18 {
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }
        let bboxArea = (maxX - minX + 1) * (maxY - minY + 1)
        guard bboxArea > 0 else { return false }
        // Outline-only Vision masks are a thin ring; a sitting dog fills much more.
        return Double(opaque) / Double(bboxArea) < 0.35
    }

    static func refineCutout(from image: UIImage) throws -> Data {
        guard var pixels = rgbaPixels(from: image),
              let cgImage = image.cgImage,
              !pixels.isEmpty else {
            throw MattingError.invalidImage
        }

        let width = cgImage.width
        let height = cgImage.height
        guard pixels.count == width * height else {
            throw MattingError.invalidImage
        }
        let background = estimateBackgroundColor(pixels: pixels, width: width, height: height)

        for index in pixels.indices {
            let pixel = pixels[index]
            let backgroundAlpha = backgroundAlpha(
                for: pixel,
                background: background,
                tolerance: 42,
                feather: 28
            )
            let scaled = Int(pixel.a) * Int(backgroundAlpha) / 255
            pixels[index].a = UInt8(clamping: scaled)
        }

        floodClearBackground(
            in: &pixels,
            width: width,
            height: height,
            background: background,
            tolerance: 44
        )

        removeNearWhiteBackground(
            in: &pixels,
            threshold: 228,
            feather: 18
        )

        guard let trimmed = trimTransparentBounds(
            pixels: pixels,
            width: width,
            height: height,
            padding: 8
        ) else {
            throw MattingError.exportFailed
        }

        var output = trimmed.pixels
        solidifyForeground(in: &output)

        return try pngData(
            pixels: output,
            width: trimmed.width,
            height: trimmed.height
        )
    }

    static func chromaKeyCutout(from image: UIImage) throws -> Data {
        guard let pixels = rgbaPixels(from: image),
              let cgImage = image.cgImage,
              !pixels.isEmpty else {
            throw MattingError.invalidImage
        }
        return try chromaKeyCutout(
            pixels: pixels,
            width: cgImage.width,
            height: cgImage.height
        )
    }

    /// Decode the original PNG/JPEG bytes with ImageIO so device `UIImage.pngData()`
    /// cannot flatten alpha or wash cream fur toward paper white.
    static func chromaKeyCutout(fromPNG data: Data) throws -> Data {
        guard let cgImage = cgImage(fromImageData: data),
              let pixels = rgbaPixels(fromNormalized: cgImage),
              !pixels.isEmpty else {
            throw MattingError.invalidImage
        }
        return try chromaKeyCutout(
            pixels: pixels,
            width: cgImage.width,
            height: cgImage.height
        )
    }

    private static func chromaKeyCutout(
        pixels original: [RGBA],
        width: Int,
        height: Int
    ) throws -> Data {
        guard width > 0, height > 0, original.count == width * height else {
            throw MattingError.invalidImage
        }

        var pixels = original
        let background = estimateBackgroundColor(pixels: original, width: width, height: height)
        let sourceCount = width * height

        let distances: [Double] = [20, 32, 44]
        for (index, distance) in distances.enumerated() {
            applyPaperFlood(
                original: original,
                into: &pixels,
                width: width,
                height: height,
                background: background,
                maxDistance: distance
            )
            if clearedPaperRatio(pixels) >= 0.08 || index == distances.count - 1 {
                break
            }
        }

        peelBackgroundFringe(
            in: &pixels,
            width: width,
            height: height,
            background: background,
            passes: 1
        )
        restoreSilhouetteFringe(
            original: original,
            into: &pixels,
            width: width,
            height: height,
            background: background,
            passes: 3
        )

        removeSmallOpaqueIslands(
            in: &pixels,
            width: width,
            height: height
        )

        let cleared = clearedPaperRatio(pixels)
        let opaqueCount = pixels.reduce(0) { $0 + ($1.a > 12 ? 1 : 0) }
        print(
            "DogCompanion [抠图] bg=(\(Int(background.r.rounded())),\(Int(background.g.rounded())),\(Int(background.b.rounded()))) cleared=\(String(format: "%.3f", cleared)) opaque=\(opaqueCount)/\(sourceCount)"
        )

        guard cleared >= 0.08 else {
            print("DogCompanion [抠图] 失败: 纸没被清掉，结果会是整张白底")
            throw MattingError.exportFailed
        }
        guard opaqueCount >= max(64, sourceCount / 50) else {
            print("DogCompanion [抠图] 失败: 主体几乎被抠空")
            throw MattingError.exportFailed
        }

        guard let trimmed = trimTransparentBounds(
            pixels: pixels,
            width: width,
            height: height,
            padding: 8
        ) else {
            throw MattingError.exportFailed
        }

        var output = trimmed.pixels
        solidifyForeground(in: &output)

        let png = try pngData(
            pixels: output,
            width: trimmed.width,
            height: trimmed.height
        )
        guard hasMeaningfulTransparency(in: png) else {
            print("DogCompanion [抠图] 失败: 导出 PNG 没有透明通道")
            throw MattingError.exportFailed
        }
        print("DogCompanion [抠图] 输出 \(trimmed.width)x\(trimmed.height)")
        return png
    }

    /// Bundled or cached cutouts may keep feathered alpha; make the subject fully opaque.
    static func opaqueCutout(from data: Data) throws -> Data {
        guard var bitmap = bitmapRGBA(from: data) else {
            throw MattingError.invalidImage
        }

        solidifyForeground(in: &bitmap.pixels)
        return try pngData(pixels: bitmap.pixels, width: bitmap.width, height: bitmap.height)
    }

    /// Never falls back to the original soft cutout — used on the display path.
    static func forceOpaqueCutout(from data: Data) -> Data {
        if let opaque = try? opaqueCutout(from: data) {
            return opaque
        }
        guard var bitmap = bitmapRGBA(from: data) else {
            return data
        }
        solidifyForeground(in: &bitmap.pixels)
        return (try? pngData(pixels: bitmap.pixels, width: bitmap.width, height: bitmap.height)) ?? data
    }

    static func opaqueUIImage(from image: UIImage) -> UIImage? {
        guard let cgImage = premultipliedCGImage(from: image) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /// Premultiplied CGImage whose transparent pixels are 0,0,0,0.
    /// SpriteKit treats unpremultiplied RGB=white + A=0 as a white rectangle.
    static func premultipliedCGImage(from image: UIImage) -> CGImage? {
        guard let cgImage = image.cgImage,
              var pixels = rgbaPixels(fromNormalized: cgImage) else {
            return nil
        }
        solidifyForeground(in: &pixels)
        for index in pixels.indices where pixels[index].a == 0 {
            pixels[index] = RGBA(r: 0, g: 0, b: 0, a: 0)
        }
        return makeCGImage(pixels: pixels, width: cgImage.width, height: cgImage.height)
    }

    /// Pixels that are visibly part of the dog become fully opaque so furniture does not show through.
    static func solidifyForeground(in pixels: inout [RGBA], minimumVisible: UInt8 = 4) {
        for index in pixels.indices {
            var pixel = pixels[index]
            guard pixel.a > minimumVisible else { continue }

            let alpha = Double(pixel.a)
            if alpha < 255 {
                let looksPremultiplied =
                    Int(pixel.r) <= Int(pixel.a) + 2 &&
                    Int(pixel.g) <= Int(pixel.a) + 2 &&
                    Int(pixel.b) <= Int(pixel.a) + 2
                if looksPremultiplied {
                    pixel.r = UInt8(clamping: Int((Double(pixel.r) * 255.0 / alpha).rounded()))
                    pixel.g = UInt8(clamping: Int((Double(pixel.g) * 255.0 / alpha).rounded()))
                    pixel.b = UInt8(clamping: Int((Double(pixel.b) * 255.0 / alpha).rounded()))
                }
            }
            pixel.a = 255
            pixels[index] = pixel
        }
    }

    private static func estimateBackgroundColor(
        pixels: [RGBA],
        width: Int,
        height: Int
    ) -> (r: Double, g: Double, b: Double) {
        let sampleSize = max(4, min(width, height) / 16)
        let corners = [
            (0, 0),
            (max(0, width - sampleSize), 0),
            (0, max(0, height - sampleSize)),
            (max(0, width - sampleSize), max(0, height - sampleSize))
        ]

        var totalR = 0.0
        var totalG = 0.0
        var totalB = 0.0
        var count = 0.0

        for (originX, originY) in corners {
            for y in originY..<min(originY + sampleSize, height) {
                for x in originX..<min(originX + sampleSize, width) {
                    let pixel = pixels[y * width + x]
                    totalR += Double(pixel.r)
                    totalG += Double(pixel.g)
                    totalB += Double(pixel.b)
                    count += 1
                }
            }
        }

        guard count > 0 else { return (255, 255, 255) }
        return (totalR / count, totalG / count, totalB / count)
    }

    private static func backgroundAlpha(
        for pixel: RGBA,
        background: (r: Double, g: Double, b: Double),
        tolerance: Double,
        feather: Double
    ) -> UInt8 {
        let distance = sqrt(
            pow(Double(pixel.r) - background.r, 2) +
            pow(Double(pixel.g) - background.g, 2) +
            pow(Double(pixel.b) - background.b, 2)
        )

        if distance <= tolerance {
            return 0
        }
        if distance >= tolerance + feather {
            return pixel.a
        }

        let blend = (distance - tolerance) / feather
        return UInt8(clamping: Int((Double(pixel.a) * blend).rounded()))
    }

    /// Walk inward from the corners so leftover paper/cardboard does not stay as a pulsing rectangle.
    private static func floodClearBackground(
        in pixels: inout [RGBA],
        width: Int,
        height: Int,
        background: (r: Double, g: Double, b: Double),
        tolerance: Double
    ) {
        guard width > 0, height > 0, pixels.count == width * height else { return }

        var visited = [Bool](repeating: false, count: pixels.count)
        var queue: [Int] = []
        queue.reserveCapacity(width + height)

        let seeds = [0, width - 1, (height - 1) * width, height * width - 1]
        for seed in seeds where seed >= 0 && seed < pixels.count {
            queue.append(seed)
        }

        let maxDistance = tolerance * tolerance

        while let current = queue.popLast() {
            if visited[current] { continue }
            visited[current] = true

            let pixel = pixels[current]
            let dr = Double(pixel.r) - background.r
            let dg = Double(pixel.g) - background.g
            let db = Double(pixel.b) - background.b
            let similarToBackground = (dr * dr + dg * dg + db * db) <= maxDistance
            guard similarToBackground else { continue }

            pixels[current].a = 0

            let x = current % width
            let y = current / width
            if x > 0 { queue.append(current - 1) }
            if x + 1 < width { queue.append(current + 1) }
            if y > 0 { queue.append(current - width) }
            if y + 1 < height { queue.append(current + width) }
        }
    }

    private static func luma(_ r: Double, _ g: Double, _ b: Double) -> Double {
        0.299 * r + 0.587 * g + 0.114 * b
    }

    private static func chroma(_ r: Double, _ g: Double, _ b: Double) -> Double {
        max(r, g, b) - min(r, g, b)
    }

    /// Paper is close to the corner color, not much darker, and not more colorful.
    /// Absolute warmth fails on device (warm whites look like fur). Matching only
    /// distance+chroma eats cream fur after color management washes it toward paper.
    private static func isPaperPixel(
        _ pixel: RGBA,
        background: (r: Double, g: Double, b: Double),
        maxDistance: Double
    ) -> Bool {
        let r = Double(pixel.r)
        let g = Double(pixel.g)
        let b = Double(pixel.b)
        let dr = r - background.r
        let dg = g - background.g
        let db = b - background.b
        if (dr * dr + dg * dg + db * db) > (maxDistance * maxDistance) {
            return false
        }
        if luma(r, g, b) < luma(background.r, background.g, background.b) - 12 {
            return false
        }
        return chroma(r, g, b) <= chroma(background.r, background.g, background.b) + 14
    }

    private static func isSubjectPixel(
        _ pixel: RGBA,
        background: (r: Double, g: Double, b: Double)
    ) -> Bool {
        let r = Double(pixel.r)
        let g = Double(pixel.g)
        let b = Double(pixel.b)
        if luma(r, g, b) < luma(background.r, background.g, background.b) - 8 {
            return true
        }
        return chroma(r, g, b) > chroma(background.r, background.g, background.b) + 12
    }

    private static func clearedPaperRatio(_ pixels: [RGBA]) -> Double {
        guard !pixels.isEmpty else { return 0 }
        let cleared = pixels.reduce(0) { $0 + ($1.a <= 12 ? 1 : 0) }
        return Double(cleared) / Double(pixels.count)
    }

    private static func applyPaperFlood(
        original: [RGBA],
        into pixels: inout [RGBA],
        width: Int,
        height: Int,
        background: (r: Double, g: Double, b: Double),
        maxDistance: Double
    ) {
        pixels = original
        floodClearPaper(
            in: &pixels,
            width: width,
            height: height,
            background: background,
            maxDistance: maxDistance
        )
        restoreSubjectPixels(original: original, into: &pixels, background: background)
    }

    private static func floodClearPaper(
        in pixels: inout [RGBA],
        width: Int,
        height: Int,
        background: (r: Double, g: Double, b: Double),
        maxDistance: Double
    ) {
        guard width > 0, height > 0, pixels.count == width * height else { return }

        var visited = [Bool](repeating: false, count: pixels.count)
        var queue: [Int] = []
        queue.reserveCapacity(width + height)

        let seeds = [0, width - 1, (height - 1) * width, height * width - 1]
        for seed in seeds where seed >= 0 && seed < pixels.count {
            queue.append(seed)
        }

        while let current = queue.popLast() {
            if visited[current] { continue }
            visited[current] = true
            guard isPaperPixel(pixels[current], background: background, maxDistance: maxDistance) else {
                continue
            }

            pixels[current] = RGBA(r: 0, g: 0, b: 0, a: 0)

            let x = current % width
            let y = current / width
            if x > 0 { queue.append(current - 1) }
            if x + 1 < width { queue.append(current + 1) }
            if y > 0 { queue.append(current - width) }
            if y + 1 < height { queue.append(current + width) }
        }
    }

    private static func restoreSubjectPixels(
        original: [RGBA],
        into pixels: inout [RGBA],
        background: (r: Double, g: Double, b: Double)
    ) {
        guard original.count == pixels.count else { return }
        for index in pixels.indices {
            let source = original[index]
            guard isSubjectPixel(source, background: background) else { continue }
            var restored = source
            restored.a = 255
            pixels[index] = restored
        }
    }

    /// Clear leftover paper wash that is still touching already-cleared paper.
    private static func peelBackgroundFringe(
        in pixels: inout [RGBA],
        width: Int,
        height: Int,
        background: (r: Double, g: Double, b: Double),
        passes: Int
    ) {
        guard width > 0, height > 0, pixels.count == width * height, passes > 0 else { return }

        for _ in 0..<passes {
            var toClear: [Int] = []
            toClear.reserveCapacity(width + height)
            for index in pixels.indices {
                if pixels[index].a <= 12 { continue }
                guard isPaperPixel(pixels[index], background: background, maxDistance: 10) else {
                    continue
                }

                let x = index % width
                let y = index / width
                var touchesPaper = false
                if x == 0 || y == 0 || x == width - 1 || y == height - 1 {
                    touchesPaper = true
                } else if pixels[index - 1].a <= 12
                    || pixels[index + 1].a <= 12
                    || pixels[index - width].a <= 12
                    || pixels[index + width].a <= 12 {
                    touchesPaper = true
                }
                if touchesPaper {
                    toClear.append(index)
                }
            }
            for index in toClear {
                pixels[index] = RGBA(r: 0, g: 0, b: 0, a: 0)
            }
        }
    }

    /// Grow back light cream fur that flood/peel ate at the silhouette, like the
    /// 金毛 crown. Only restore pixels that are not nearly identical to paper.
    private static func restoreSilhouetteFringe(
        original: [RGBA],
        into pixels: inout [RGBA],
        width: Int,
        height: Int,
        background: (r: Double, g: Double, b: Double),
        passes: Int
    ) {
        guard original.count == pixels.count, width > 0, height > 0, passes > 0 else { return }

        for _ in 0..<passes {
            var toRestore: [Int] = []
            toRestore.reserveCapacity(width + height)
            for index in pixels.indices {
                if pixels[index].a > 12 { continue }
                let source = original[index]
                if isPaperPixel(source, background: background, maxDistance: 10) {
                    continue
                }
                let r = Double(source.r)
                let g = Double(source.g)
                let b = Double(source.b)
                if chroma(r, g, b) < 8,
                   luma(r, g, b) >= luma(background.r, background.g, background.b) - 6 {
                    continue
                }

                let x = index % width
                let y = index / width
                var touchesSubject = false
                if x > 0 && pixels[index - 1].a > 12 { touchesSubject = true }
                else if x + 1 < width && pixels[index + 1].a > 12 { touchesSubject = true }
                else if y > 0 && pixels[index - width].a > 12 { touchesSubject = true }
                else if y + 1 < height && pixels[index + width].a > 12 { touchesSubject = true }
                if touchesSubject {
                    toRestore.append(index)
                }
            }
            for index in toRestore {
                var restored = original[index]
                restored.a = 255
                pixels[index] = restored
            }
        }
    }

    /// Drop leftover paper speckles; keep the main dog silhouette.
    private static func removeSmallOpaqueIslands(
        in pixels: inout [RGBA],
        width: Int,
        height: Int
    ) {
        guard width > 0, height > 0, pixels.count == width * height else { return }
        var visited = [Bool](repeating: false, count: pixels.count)
        var islands: [[Int]] = []
        var largest = 0
        var stack: [Int] = []

        for start in 0..<pixels.count {
            if visited[start] || pixels[start].a <= 12 { continue }
            stack.append(start)
            var island: [Int] = []
            while let current = stack.popLast() {
                if visited[current] { continue }
                visited[current] = true
                guard pixels[current].a > 12 else { continue }
                island.append(current)
                let x = current % width
                let y = current / width
                if x > 0 { stack.append(current - 1) }
                if x + 1 < width { stack.append(current + 1) }
                if y > 0 { stack.append(current - width) }
                if y + 1 < height { stack.append(current + width) }
            }
            if !island.isEmpty {
                islands.append(island)
                largest = max(largest, island.count)
            }
        }

        let minKeep = max(64, largest / 12)
        for island in islands where island.count < minKeep {
            for index in island {
                pixels[index].a = 0
            }
        }
    }

    private static func removeNearWhiteBackground(
        in pixels: inout [RGBA],
        threshold: UInt8,
        feather: UInt8
    ) {
        for index in pixels.indices {
            let pixel = pixels[index]
            let minimumChannel = min(pixel.r, pixel.g, pixel.b)
            guard minimumChannel >= threshold - feather else { continue }

            let whiteDistance = Double(minimumChannel - (threshold - feather))
            let removal = min(1.0, whiteDistance / Double(max(Int(feather), 1)))
            let keep = 1.0 - removal
            pixels[index].a = UInt8(clamping: Int((Double(pixels[index].a) * keep).rounded()))
        }
    }

    private static func trimTransparentBounds(
        pixels: [RGBA],
        width: Int,
        height: Int,
        padding: Int
    ) -> (pixels: [RGBA], width: Int, height: Int)? {
        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0

        for y in 0..<height {
            for x in 0..<width {
                if pixels[y * width + x].a > 12 {
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }

        guard minX <= maxX, minY <= maxY else { return nil }

        minX = max(0, minX - padding)
        minY = max(0, minY - padding)
        maxX = min(width - 1, maxX + padding)
        maxY = min(height - 1, maxY + padding)

        let trimmedWidth = maxX - minX + 1
        let trimmedHeight = maxY - minY + 1
        var trimmed = [RGBA](repeating: RGBA(r: 0, g: 0, b: 0, a: 0), count: trimmedWidth * trimmedHeight)

        for y in 0..<trimmedHeight {
            for x in 0..<trimmedWidth {
                trimmed[y * trimmedWidth + x] = pixels[(y + minY) * width + (x + minX)]
            }
        }

        return (trimmed, trimmedWidth, trimmedHeight)
    }

    private struct BitmapRGBA {
        var pixels: [RGBA]
        var width: Int
        var height: Int
    }

    private static func cgImage(fromImageData data: Data) -> CGImage? {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, options) else {
            return UIImage(data: data)?.cgImage
        }
        return CGImageSourceCreateImageAtIndex(source, 0, options) ?? UIImage(data: data)?.cgImage
    }

    private static func bitmapRGBA(from data: Data) -> BitmapRGBA? {
        if let cgImage = cgImage(fromImageData: data),
           let pixels = rgbaPixels(fromNormalized: cgImage),
           !pixels.isEmpty,
           pixels.count == cgImage.width * cgImage.height {
            return BitmapRGBA(pixels: pixels, width: cgImage.width, height: cgImage.height)
        }
        guard let image = UIImage(data: data) else { return nil }
        return bitmapRGBA(from: image)
    }

    private static func bitmapRGBA(from image: UIImage) -> BitmapRGBA? {
        guard let cgImage = image.cgImage,
              let pixels = rgbaPixels(fromNormalized: cgImage),
              !pixels.isEmpty else {
            return nil
        }
        let width = cgImage.width
        let height = cgImage.height
        guard pixels.count == width * height else { return nil }
        return BitmapRGBA(pixels: pixels, width: width, height: height)
    }

    private static func rgbaPixels(from image: UIImage) -> [RGBA]? {
        guard let cgImage = image.cgImage else { return nil }
        return rgbaPixels(fromNormalized: cgImage)
    }

    private static func rgbaPixels(fromNormalized cgImage: CGImage) -> [RGBA]? {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()

        var pixelData = [UInt8](repeating: 0, count: height * bytesPerRow)
        let drew = pixelData.withUnsafeMutableBytes { buffer -> Bool in
            guard let base = buffer.baseAddress else { return false }
            guard let context = CGContext(
                data: base,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) else {
                return false
            }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drew else { return nil }

        var pixels: [RGBA] = []
        pixels.reserveCapacity(width * height)
        for index in stride(from: 0, to: pixelData.count, by: 4) {
            var r = pixelData[index]
            var g = pixelData[index + 1]
            var b = pixelData[index + 2]
            let a = pixelData[index + 3]
            if a > 0 && a < 255 {
                let scale = 255.0 / Double(a)
                r = UInt8(clamping: Int((Double(r) * scale).rounded()))
                g = UInt8(clamping: Int((Double(g) * scale).rounded()))
                b = UInt8(clamping: Int((Double(b) * scale).rounded()))
            }
            pixels.append(RGBA(r: r, g: g, b: b, a: a))
        }
        return pixels
    }

    /// Draws through a bitmap context so device color spaces / oriented images decode consistently.
    static func normalizedCGImage(from image: UIImage) -> CGImage? {
        guard image.size.width > 0, image.size.height > 0 else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = max(image.scale, 1)
        format.opaque = false
        format.preferredRange = .standard
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }.cgImage
    }

    private static func pngData(pixels: [RGBA], width: Int, height: Int) throws -> Data {
        guard let cgImage = makeCGImage(pixels: pixels, width: width, height: height) else {
            throw MattingError.exportFailed
        }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            "public.png" as CFString,
            1,
            nil
        ) else {
            throw MattingError.exportFailed
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw MattingError.exportFailed
        }
        return data as Data
    }

    private static func makeCGImage(pixels: [RGBA], width: Int, height: Int) -> CGImage? {
        guard width > 0, height > 0, pixels.count == width * height else {
            return nil
        }

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var pixelData = [UInt8](repeating: 0, count: height * bytesPerRow)

        // iOS bitmap contexts require premultiplied alpha. kCGImageAlphaLast fails on device.
        for index in pixels.indices {
            let pixel = pixels[index]
            let offset = index * 4
            let alpha = Double(pixel.a) / 255.0
            pixelData[offset] = UInt8(clamping: Int((Double(pixel.r) * alpha).rounded()))
            pixelData[offset + 1] = UInt8(clamping: Int((Double(pixel.g) * alpha).rounded()))
            pixelData[offset + 2] = UInt8(clamping: Int((Double(pixel.b) * alpha).rounded()))
            pixelData[offset + 3] = pixel.a
        }

        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        return pixelData.withUnsafeMutableBytes { buffer in
            guard let base = buffer.baseAddress else { return nil }
            guard let context = CGContext(
                data: base,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) else {
                return nil
            }
            return context.makeImage()
        }
    }
}

struct MattingService {
    func extractCutout(from image: UIImage, pose: CompanionPose = .sit) async throws -> Data {
        let data = try await Task.detached(priority: .userInitiated) {
            try Self.performCutout(on: image)
        }.value
        archiveForegroundCutout(data, pose: pose)
        return data
    }

    private func archiveForegroundCutout(_ data: Data, pose: CompanionPose) {
        do {
            _ = try GeneratedImageArchive.saveForegroundCutout(data, pose: pose)
        } catch {
            print("DogCompanion [前景抠图] 保存失败: \(error)")
        }
    }

    private static func performCutout(on image: UIImage) throws -> Data {
        let chroma = try CutoutImageProcessor.chromaKeyCutout(from: image)
        let chromaOpaque = CutoutImageProcessor.forceOpaqueCutout(from: chroma)

        if let visionData = try? visionCutout(from: image),
           CutoutImageProcessor.hasMeaningfulTransparency(in: visionData) {
            let visionOpaque = CutoutImageProcessor.forceOpaqueCutout(from: visionData)
            if CutoutImageProcessor.hasInteriorHoles(in: visionOpaque) {
                return chromaOpaque
            }
            return visionOpaque
        }
        return chromaOpaque
    }

    private static func visionCutout(from image: UIImage) throws -> Data {
        guard let cgImage = image.cgImage else {
            throw MattingError.invalidImage
        }

        let request = VNGenerateForegroundInstanceMaskRequest()
        configureForSimulator(request)

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observation = request.results?.first else {
            throw MattingError.maskGenerationFailed
        }

        let instances = observation.allInstances
        guard !instances.isEmpty else {
            throw MattingError.maskGenerationFailed
        }

        let maskPixelBuffer = try observation.generateScaledMaskForImage(
            forInstances: instances,
            from: handler
        )

        guard let composited = try composite(
            original: cgImage,
            maskPixelBuffer: maskPixelBuffer
        ) else {
            throw MattingError.exportFailed
        }

        return composited
    }

    private static func composite(
        original: CGImage,
        maskPixelBuffer: CVPixelBuffer
    ) throws -> Data? {
        CVPixelBufferLockBaseAddress(maskPixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(maskPixelBuffer, .readOnly) }

        let maskWidth = CVPixelBufferGetWidth(maskPixelBuffer)
        let maskHeight = CVPixelBufferGetHeight(maskPixelBuffer)
        guard let maskBase = CVPixelBufferGetBaseAddress(maskPixelBuffer) else {
            return nil
        }

        let maskBytesPerRow = CVPixelBufferGetBytesPerRow(maskPixelBuffer)
        let width = original.width
        let height = original.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        var pixelData = [UInt8](repeating: 0, count: height * bytesPerRow)
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

        context.draw(original, in: CGRect(x: 0, y: 0, width: width, height: height))

        for y in 0..<height {
            let maskY = min(maskHeight - 1, y * maskHeight / height)
            let maskRow = maskBase.advanced(by: maskY * maskBytesPerRow).assumingMemoryBound(to: UInt8.self)

            for x in 0..<width {
                let maskX = min(maskWidth - 1, x * maskWidth / width)
                let maskValue = Int(maskRow[maskX])
                let offset = y * bytesPerRow + x * 4
                for channel in 0..<3 {
                    pixelData[offset + channel] = UInt8(
                        (Int(pixelData[offset + channel]) * maskValue) / 255
                    )
                }
                pixelData[offset + 3] = UInt8(
                    (Int(pixelData[offset + 3]) * maskValue) / 255
                )
            }
        }

        guard let outputContext = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ), let outputCG = outputContext.makeImage() else {
            return nil
        }

        return UIImage(cgImage: outputCG).pngData()
    }

    private static func configureForSimulator(_ request: VNRequest) {
        #if targetEnvironment(simulator)
        if #available(iOS 17.0, *) {
            for device in MLComputeDevice.allComputeDevices {
                if case .cpu = device {
                    request.setComputeDevice(device, for: .main)
                    break
                }
            }
        } else {
            request.usesCPUOnly = true
        }
        #endif
    }
}
