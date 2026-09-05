import UIKit
import XCTest
@testable import DogCompanion

final class ResourceDogServiceTests: XCTestCase {
    private var tempRoot: URL!
    private var cacheRoot: URL!
    private var catalog: ResourceDogCatalog!
    private var portraitSpy: PortraitGeneratorSpy!
    private var cutoutSpy: CutoutExtractorSpy!

    override func setUpWithError() throws {
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("ResourceDogServiceTests-\(UUID().uuidString)", isDirectory: true)
        cacheRoot = tempRoot.appendingPathComponent("cache", isDirectory: true)
        ResourceDogAssetCache.rootDirectory = cacheRoot

        let resourceRoot = tempRoot.appendingPathComponent("resource", isDirectory: true)
        let dogFolder = resourceRoot.appendingPathComponent("金毛", isDirectory: true)
        try FileManager.default.createDirectory(at: dogFolder, withIntermediateDirectories: true)
        try makeTinyPNG().write(to: dogFolder.appendingPathComponent("金毛寻回犬.jpg"))

        catalog = ResourceDogCatalog(resourceRootOverride: resourceRoot)
        portraitSpy = PortraitGeneratorSpy()
        cutoutSpy = CutoutExtractorSpy()
    }

    override func tearDownWithError() throws {
        ResourceDogAssetCache.rootDirectory = nil
        try? FileManager.default.removeItem(at: tempRoot)
    }

    func testLoadAssetsUsesCachedPortraitWithoutCallingAPI() async throws {
        let cachedPortrait = makeTinyPNG()
        let cachedCutout = makeTinyPNG()
        try ResourceDogAssetCache.savePortrait(cachedPortrait, for: "金毛")
        try ResourceDogAssetCache.saveCutout(cachedCutout, for: "金毛")

        var service = ResourceDogService()
        service.catalog = catalog
        service.portraitGenerator = portraitSpy
        service.cutoutExtractor = cutoutSpy

        let assets = try await service.loadAssets(for: "金毛")

        XCTAssertEqual(assets.portraitData, cachedPortrait)
        XCTAssertEqual(assets.cutoutData, cachedCutout)
        XCTAssertEqual(portraitSpy.callCount, 0)
        XCTAssertEqual(cutoutSpy.callCount, 0)
    }

    func testLoadAssetsCachesPortraitAfterFirstGeneration() async throws {
        let generatedPortrait = makeTinyPNG()
        let generatedCutout = makeTinyPNG()
        portraitSpy.result = generatedPortrait
        cutoutSpy.result = generatedCutout

        var service = ResourceDogService()
        service.catalog = catalog
        service.portraitGenerator = portraitSpy
        service.cutoutExtractor = cutoutSpy

        _ = try await service.loadAssets(for: "金毛")

        XCTAssertEqual(portraitSpy.callCount, 1)
        XCTAssertEqual(cutoutSpy.callCount, 1)
        XCTAssertEqual(ResourceDogAssetCache.portraitData(for: "金毛"), generatedPortrait)
        XCTAssertEqual(ResourceDogAssetCache.cutoutData(for: "金毛"), generatedCutout)

        portraitSpy.callCount = 0
        cutoutSpy.callCount = 0

        let assets = try await service.loadAssets(for: "金毛")

        XCTAssertEqual(assets.portraitData, generatedPortrait)
        XCTAssertEqual(assets.cutoutData, generatedCutout)
        XCTAssertEqual(portraitSpy.callCount, 0)
        XCTAssertEqual(cutoutSpy.callCount, 0)
    }

    private func makeTinyPNG() -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
        let image = renderer.image { context in
            UIColor.brown.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
        return image.pngData()!
    }
}

private final class PortraitGeneratorSpy: ResourceDogPortraitGenerating {
    var callCount = 0
    var result = Data()

    func generateComicPortrait(
        from image: UIImage,
        style: StyleTemplate,
        pose: CompanionPose
    ) async throws -> Data {
        callCount += 1
        return result
    }
}

private final class CutoutExtractorSpy: ResourceDogCutoutExtracting {
    var callCount = 0
    var result = Data()

    func extractCutout(from image: UIImage, pose: CompanionPose) async throws -> Data {
        callCount += 1
        return result
    }
}
