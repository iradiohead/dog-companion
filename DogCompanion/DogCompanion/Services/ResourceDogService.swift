import Foundation
import ImageIO
import UIKit

struct CompanionAssets {
    let portraitData: Data
    let cutoutData: Data
    let coatPalette: CoatPalette
}

/// Single entry point for bundled `resource/` dogs: list, preview, and full asset loading.
struct ResourceDogService {
    var catalog = ResourceDogCatalog()
    var generationService = GenerationService()
    var mattingService = MattingService()

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
            guard let url = catalog.previewImageURL(for: dogName),
                  let data = try? Data(contentsOf: url),
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
        } else {
            guard let originalURL = contents.originalURL else {
                throw ResourceDogError.missingOriginal(dogName)
            }
            guard let originalImage = UIImage(contentsOfFile: originalURL.path) else {
                throw ResourceDogError.invalidImage(dogName)
            }
            portraitData = try await generationService.generateComicPortrait(
                from: originalImage,
                style: .default,
                pose: .sit
            )
        }

        guard let portraitImage = UIImage(data: portraitData) else {
            throw ResourceDogError.invalidImage(dogName)
        }

        let cutoutData: Data
        if let foregroundURL = contents.foregroundURL {
            cutoutData = try Data(contentsOf: foregroundURL)
        } else {
            cutoutData = try await mattingService.extractCutout(from: portraitImage, pose: .sit)
        }

        return CompanionAssets(
            portraitData: portraitData,
            cutoutData: cutoutData,
            coatPalette: CoatSampler.snap(from: portraitImage)
        )
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
