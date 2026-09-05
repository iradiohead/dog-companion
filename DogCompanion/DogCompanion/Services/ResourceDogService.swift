import Foundation
import ImageIO
import UIKit

struct CompanionAssets {
    let portraitData: Data
    let cutoutData: Data
    let coatPalette: CoatPalette
}

enum ResourceDogLoadStatus: Equatable {
    case readingResources
    case readingPortrait
    case generatingPortrait
    case readingCutout
    case extractingCutout
    case finishing

    var message: String {
        switch self {
        case .readingResources:
            return "正在读取狗狗资源…"
        case .readingPortrait:
            return "正在读取手绘形象…"
        case .generatingPortrait:
            return "正在生成手绘形象…"
        case .readingCutout:
            return "正在读取前景图层…"
        case .extractingCutout:
            return "正在抠出前景图层…"
        case .finishing:
            return "马上就好啦…"
        }
    }
}

struct ResourceDogLoadPlan: Equatable {
    var willGeneratePortrait: Bool
    var willExtractCutout: Bool

    var messages: [String] {
        var steps = [ResourceDogLoadStatus.readingResources.message]
        steps.append(
            willGeneratePortrait
                ? ResourceDogLoadStatus.generatingPortrait.message
                : ResourceDogLoadStatus.readingPortrait.message
        )
        steps.append(
            willExtractCutout
                ? ResourceDogLoadStatus.extractingCutout.message
                : ResourceDogLoadStatus.readingCutout.message
        )
        steps.append(ResourceDogLoadStatus.finishing.message)
        return steps
    }
}

protocol ResourceDogPortraitGenerating {
    func generateComicPortrait(from image: UIImage, style: StyleTemplate, pose: CompanionPose) async throws -> Data
}

protocol ResourceDogCutoutExtracting {
    func extractCutout(from image: UIImage, pose: CompanionPose) async throws -> Data
    func extractCutout(fromPNG data: Data, pose: CompanionPose) async throws -> Data
}

extension ResourceDogCutoutExtracting {
    func extractCutout(fromPNG data: Data, pose: CompanionPose) async throws -> Data {
        guard let image = UIImage(data: data) else {
            throw MattingError.invalidImage
        }
        return try await extractCutout(from: image, pose: pose)
    }
}

extension GenerationService: ResourceDogPortraitGenerating {}
extension MattingService: ResourceDogCutoutExtracting {}

struct ChromaKeyCutoutExtractor: ResourceDogCutoutExtracting {
    func extractCutout(from image: UIImage, pose: CompanionPose) async throws -> Data {
        guard let png = image.pngData() else {
            throw MattingError.invalidImage
        }
        return try await extractCutout(fromPNG: png, pose: pose)
    }

    func extractCutout(fromPNG data: Data, pose: CompanionPose) async throws -> Data {
        _ = pose
        do {
            return try await Task.detached(priority: .userInitiated) {
                let chroma = try CutoutImageProcessor.chromaKeyCutout(fromPNG: data)
                return CutoutImageProcessor.forceOpaqueCutout(from: chroma)
            }.value
        } catch {
            print("DogCompanion [抠图] 失败: \(error.localizedDescription)")
            throw error
        }
    }
}

/// Single entry point for bundled `resource/` dogs: list, preview, and full asset loading.
struct ResourceDogService {
    var catalog = ResourceDogCatalog()
    var portraitGenerator: any ResourceDogPortraitGenerating = GenerationService()
    var cutoutExtractor: any ResourceDogCutoutExtracting = ChromaKeyCutoutExtractor()

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

    func loadPlan(for dogName: String) -> ResourceDogLoadPlan {
        let contents = try? catalog.folderContents(for: dogName)
        let hasBundledPortrait = contents?.handDrawnURL != nil
        let hasCachedPortrait = ResourceDogAssetCache.portraitData(for: dogName) != nil
        let hasBundledCutout = contents?.foregroundURL != nil
        let cachedCutout = ResourceDogAssetCache.cutoutData(for: dogName)
        let hasUsableCachedCutout = cachedCutout.map { Self.isUsableCutout($0) } ?? false
        return ResourceDogLoadPlan(
            willGeneratePortrait: !hasBundledPortrait && !hasCachedPortrait,
            willExtractCutout: !hasBundledCutout && !hasUsableCachedCutout
        )
    }

    func loadAssets(
        for dogName: String,
        onStatus: (@MainActor (ResourceDogLoadStatus) -> Void)? = nil
    ) async throws -> CompanionAssets {
        await report(.readingResources, onStatus)
        let contents = try catalog.folderContents(for: dogName)

        let portraitData: Data
        if let handDrawnURL = contents.handDrawnURL {
            await report(.readingPortrait, onStatus)
            portraitData = try Data(contentsOf: handDrawnURL)
        } else if let cached = ResourceDogAssetCache.portraitData(for: dogName) {
            await report(.readingPortrait, onStatus)
            portraitData = cached
        } else {
            guard let originalURL = contents.originalURL else {
                throw ResourceDogError.missingOriginal(dogName)
            }
            guard let originalImage = UIImage(contentsOfFile: originalURL.path) else {
                throw ResourceDogError.invalidImage(dogName)
            }
            await report(.generatingPortrait, onStatus)
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
            await report(.readingCutout, onStatus)
            let raw = try Data(contentsOf: foregroundURL)
            cutoutData = Self.finalizeCutout(raw)
        } else if let cached = ResourceDogAssetCache.cutoutData(for: dogName),
                  Self.isUsableCutout(cached) {
            await report(.readingCutout, onStatus)
            cutoutData = Self.finalizeCutout(cached)
        } else {
            await report(.extractingCutout, onStatus)
            print("DogCompanion [ResourceDog] 开始抠图: \(dogName)")
            let extracted = try await cutoutExtractor.extractCutout(fromPNG: portraitData, pose: .sit)
            let opaque = Self.finalizeCutout(extracted)
            let saved = try ResourceDogAssetCache.saveCutout(opaque, for: dogName)
            print("DogCompanion [ResourceDog] 已保存抠图: \(saved.path) bytes=\(opaque.count)")
            cutoutData = opaque
        }

        await report(.finishing, onStatus)
        return CompanionAssets(
            portraitData: portraitData,
            cutoutData: cutoutData,
            coatPalette: CoatSampler.snap(from: portraitImage)
        )
    }

    private func report(
        _ status: ResourceDogLoadStatus,
        _ onStatus: (@MainActor (ResourceDogLoadStatus) -> Void)?
    ) async {
        guard let onStatus else { return }
        await onStatus(status)
    }

    private static func finalizeCutout(_ data: Data) -> Data {
        CutoutImageProcessor.forceOpaqueCutout(from: data)
    }

    private static func isUsableCutout(_ data: Data) -> Bool {
        let opaque = finalizeCutout(data)
        return !CutoutImageProcessor.needsCutoutRefresh(opaque)
            && !CutoutImageProcessor.hasInteriorHoles(in: opaque)
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
