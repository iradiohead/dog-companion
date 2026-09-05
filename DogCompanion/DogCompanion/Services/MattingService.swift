import UIKit
import Vision
import CoreImage
import CoreML

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
    struct RGBA {
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

        let cornerSamples = [
            pixels[0],
            pixels[width - 1],
            pixels[(height - 1) * width],
            pixels[height * width - 1]
        ]
        if cornerSamples.filter({ $0.a > 200 }).count >= 3 {
            return true
        }

        let opaqueCount = pixels.filter { $0.a > 220 }.count
        return Double(opaqueCount) / Double(pixels.count) > 0.72
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

        return try pngData(
            pixels: trimmed.pixels,
            width: trimmed.width,
            height: trimmed.height
        )
    }

    static func chromaKeyCutout(from image: UIImage) throws -> Data {
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
            let alpha = backgroundAlpha(
                for: pixel,
                background: background,
                tolerance: 36,
                feather: 24
            )
            pixels[index].a = alpha
        }

        floodClearBackground(
            in: &pixels,
            width: width,
            height: height,
            background: background,
            tolerance: 38
        )

        removeNearWhiteBackground(
            in: &pixels,
            threshold: 224,
            feather: 20
        )

        guard let trimmed = trimTransparentBounds(
            pixels: pixels,
            width: width,
            height: height,
            padding: 8
        ) else {
            throw MattingError.exportFailed
        }

        return try pngData(
            pixels: trimmed.pixels,
            width: trimmed.width,
            height: trimmed.height
        )
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
            let alreadyThin = pixel.a < 48
            guard similarToBackground || alreadyThin else { continue }

            pixels[current].a = 0

            let x = current % width
            let y = current / width
            if x > 0 { queue.append(current - 1) }
            if x + 1 < width { queue.append(current + 1) }
            if y > 0 { queue.append(current - width) }
            if y + 1 < height { queue.append(current + width) }
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

    private static func rgbaPixels(from image: UIImage) -> [RGBA]? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
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

    private static func pngData(pixels: [RGBA], width: Int, height: Int) throws -> Data {
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var pixelData = [UInt8](repeating: 0, count: height * bytesPerRow)

        for index in pixels.indices {
            let offset = index * 4
            pixelData[offset] = pixels[index].r
            pixelData[offset + 1] = pixels[index].g
            pixelData[offset + 2] = pixels[index].b
            pixelData[offset + 3] = pixels[index].a
        }

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
        ), let cgImage = context.makeImage() else {
            throw MattingError.exportFailed
        }

        guard let pngData = UIImage(cgImage: cgImage).pngData() else {
            throw MattingError.exportFailed
        }
        return pngData
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
            #if DEBUG
            print("GeneratedImageArchive foreground cutout save failed: \(error)")
            #endif
        }
    }

    private static func performCutout(on image: UIImage) throws -> Data {
        if let visionData = try? visionCutout(from: image),
           CutoutImageProcessor.hasMeaningfulTransparency(in: visionData) {
            return try CutoutImageProcessor.refineCutout(from: UIImage(data: visionData) ?? image)
        }
        return try CutoutImageProcessor.chromaKeyCutout(from: image)
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
                let maskValue = maskRow[maskX]
                let offset = y * bytesPerRow + x * 4
                pixelData[offset + 3] = UInt8(
                    (Int(pixelData[offset + 3]) * Int(maskValue)) / 255
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
