import UIKit
import Vision
import CoreImage

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
        guard let cgImage = image.cgImage else {
            throw MattingError.invalidImage
        }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observation = request.results?.first else {
            throw MattingError.maskGenerationFailed
        }

        let instances = observation.allInstances
        guard !instances.isEmpty else {
            throw MattingError.maskGenerationFailed
        }

        let inputImage = CIImage(cgImage: cgImage)
        let maskedImage = try observation.generateMaskedImage(
            of: inputImage,
            forInstances: instances,
            croppedToInstancesExtent: true
        )

        let context = CIContext()
        guard let outputCG = context.createCGImage(maskedImage, from: maskedImage.extent) else {
            throw MattingError.exportFailed
        }

        guard let pngData = UIImage(cgImage: outputCG).pngData() else {
            throw MattingError.exportFailed
        }
        return pngData
    }
}
