import Foundation
import ImageIO
import UIKit

struct CompanionAssets {
    let portraitData: Data
    let cutoutData: Data
    let coatPalette: CoatPalette
}

protocol ResourceDogPortraitGenerating {
    func generateComicPortrait(from image: UIImage, style: StyleTemplate, pose: CompanionPose) async throws -> Data
}

protocol ResourceDogCutoutExtracting {
    func extractCutout(from image: UIImage, pose: CompanionPose) async throws -> Data
}

extension GenerationService: ResourceDogPortraitGenerating {}
extension MattingService: ResourceDogCutoutExtracting {}

/// Single entry point for bundled `resource/` dogs: list, preview, and full asset loading.
struct ResourceDogService {
    var catalog = ResourceDogCatalog()
    var portraitGenerator: any ResourceDogPortraitGenerating = GenerationService()
    var cutoutExtractor: any ResourceDogCutoutExtracting = MattingService()

    private static let previewCache = NSCache<NSString, UIImage>()
    private static let maxPreviewDimension: CGFloat = 480

    func availableDogs() -> [String] {
        catalog.availableDogNames()
    }

    func preloadPreviews(for dogNames: [String]) {
        guard !dogNames.isEmpty else { return }
        Task.detached(priority: .utility) {
            for dogName in dogNames {
                _ = await previewImage(for: dogName)
            }
        }
    }

    func previewImage(for dogName: String) async -> PlatformImage? {
        let cacheKey = dogName as NSString
        if let cached = Self.previewCache.object(forKey: cacheKey) {
            return cached
        }

        return await Task.detached(priority: .userInitiated) {
            guard let data = previewSourceData(for: dogName),
                  let image = Self.downsample(data: data) else {
                return nil
            }
            Self.previewCache.setObject(image, forKey: cacheKey)
            return image
        }.value
    }

    func loadAssets(for dogName: String) async throws -> CompanionAssets {
        let contents = try catalog.folderContents(for: dogName)

        let portraitData: Data
        if let handDrawnURL = contents.handDrawnURL {
            portraitData = try Data(contentsOf: handDrawnURL)
        } else if let cached = ResourceDogAssetCache.portraitData(for: dogName) {
            portraitData = cached
        } else {
            guard let originalURL = contents.originalURL else {
                throw ResourceDogError.missingOriginal(dogName)
            }
            guard let originalImage = UIImage(contentsOfFile: originalURL.path) else {
                throw ResourceDogError.invalidImage(dogName)
            }
            let generated = try await portraitGenerator.generateComicPortrait(
                from: originalImage,
                style: .default,
                pose: .sit
            )
            try ResourceDogAssetCache.savePortrait(generated, for: dogName)
            portraitData = generated
        }

        guard let portraitImage = UIImage(data: portraitData) else {
            throw ResourceDogError.invalidImage(dogName)
        }

        let cutoutData: Data
        if let foregroundURL = contents.foregroundURL {
            let raw = try Data(contentsOf: foregroundURL)
            cutoutData = try CutoutImageProcessor.opaqueCutout(from: raw)
        } else if let cached = ResourceDogAssetCache.cutoutData(for: dogName) {
            cutoutData = cached
        } else {
            let extracted = try await cutoutExtractor.extractCutout(from: portraitImage, pose: .sit)
            try ResourceDogAssetCache.saveCutout(extracted, for: dogName)
            cutoutData = extracted
        }

        return CompanionAssets(
            portraitData: portraitData,
            cutoutData: cutoutData,
            coatPalette: CoatSampler.snap(from: portraitImage)
        )
    }

    private func previewSourceData(for dogName: String) -> Data? {
        if let contents = try? catalog.folderContents(for: dogName) {
            if let handDrawnURL = contents.handDrawnURL,
               let data = try? Data(contentsOf: handDrawnURL) {
                return data
            }
            if let cached = ResourceDogAssetCache.portraitData(for: dogName) {
                return cached
            }
            if let previewURL = contents.previewURL,
               let data = try? Data(contentsOf: previewURL) {
                return data
            }
        }
        if let cachedURL = ResourceDogAssetCache.portraitURL(for: dogName) {
            return try? Data(contentsOf: cachedURL)
        }
        return nil
    }

    private static func downsample(data: Data) -> UIImage? {
        let options: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else {
            return UIImage(data: data)
        }

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: maxPreviewDimension,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            thumbnailOptions as CFDictionary
        ) else {
            return UIImage(data: data)
        }
        return UIImage(cgImage: cgImage)
    }
}
