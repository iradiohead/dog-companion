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

struct MattingService {
    func extractCutout(from image: UIImage) async throws -> Data {
        try await Task.detached(priority: .userInitiated) {
            try Self.performCutout(on: image)
        }.value
    }

    private static func performCutout(on image: UIImage) throws -> Data {
        do {
            return try visionCutout(from: image)
        } catch {
            return try whiteBackgroundCutout(from: image)
        }
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

        let maskPixelBuffer = try observation.generateMaskedImage(
            ofInstances: instances,
            from: handler,
            croppedToInstancesExtent: true
        )

        let maskedImage = CIImage(cvPixelBuffer: maskPixelBuffer)
        return try pngData(from: maskedImage)
    }

    /// Fallback for comic images generated with a solid light background.
    private static func whiteBackgroundCutout(from image: UIImage) throws -> Data {
        guard let cgImage = image.cgImage else {
            throw MattingError.invalidImage
        }

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
            throw MattingError.exportFailed
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let threshold: UInt8 = 235
        for index in stride(from: 0, to: pixelData.count, by: 4) {
            let red = pixelData[index]
            let green = pixelData[index + 1]
            let blue = pixelData[index + 2]
            if red >= threshold, green >= threshold, blue >= threshold {
                pixelData[index + 3] = 0
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
            throw MattingError.exportFailed
        }

        guard let pngData = UIImage(cgImage: outputCG).pngData() else {
            throw MattingError.exportFailed
        }
        return pngData
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

    private static func pngData(from image: CIImage) throws -> Data {
        let context = CIContext()
        guard let outputCG = context.createCGImage(image, from: image.extent) else {
            throw MattingError.exportFailed
        }

        guard let pngData = UIImage(cgImage: outputCG).pngData() else {
            throw MattingError.exportFailed
        }
        return pngData
    }
}
