import Foundation
import ImageIO
import UIKit

enum ResourceDogPreviewLoader {
    private static let cache = NSCache<NSString, UIImage>()
    private static let maxPreviewDimension: CGFloat = 480

    static func preload(for dogNames: [String], catalog: ResourceDogCatalog = ResourceDogCatalog()) {
        guard !dogNames.isEmpty else { return }
        Task.detached(priority: .utility) {
            for dogName in dogNames {
                _ = await load(for: dogName, catalog: catalog)
            }
        }
    }

    static func load(for dogName: String, catalog: ResourceDogCatalog = ResourceDogCatalog()) async -> PlatformImage? {
        let cacheKey = dogName as NSString
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        return await Task.detached(priority: .userInitiated) {
            guard let url = catalog.previewImageURL(for: dogName),
                  let data = try? Data(contentsOf: url),
                  let image = downsample(data: data, maxDimension: maxPreviewDimension) else {
                return nil
            }
            cache.setObject(image, forKey: cacheKey)
            return image
        }.value
    }

    static func clearCache() {
        cache.removeAllObjects()
    }

    private static func downsample(data: Data, maxDimension: CGFloat) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else {
            return UIImage(data: data)
        }

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
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
