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
        XCTAssertFalse(CutoutImageProcessor.needsCutoutRefresh(assets.cutoutData))
        XCTAssertEqual(portraitSpy.callCount, 0)
        XCTAssertEqual(cutoutSpy.callCount, 0)
    }

    func testLoadAssetsOpaqueifiesSoftCachedCutout() async throws {
        let softCutout = try makeSoftCutoutPNG()
        try ResourceDogAssetCache.savePortrait(makeTinyPNG(), for: "金毛")
        try ResourceDogAssetCache.saveCutout(softCutout, for: "金毛")

        var service = ResourceDogService()
        service.catalog = catalog
        service.portraitGenerator = portraitSpy
        service.cutoutExtractor = cutoutSpy

        let assets = try await service.loadAssets(for: "金毛")

        XCTAssertFalse(CutoutImageProcessor.needsCutoutRefresh(assets.cutoutData))
        XCTAssertNotEqual(assets.cutoutData, softCutout)
        XCTAssertEqual(cutoutSpy.callCount, 0)
    }

    func testLoadAssetsCachesOpaqueCutoutAfterFirstGeneration() async throws {
        let generatedPortrait = makeTinyPNG()
        let softCutout = try makeSoftCutoutPNG()
        portraitSpy.result = generatedPortrait
        cutoutSpy.result = softCutout

        var service = ResourceDogService()
        service.catalog = catalog
        service.portraitGenerator = portraitSpy
        service.cutoutExtractor = cutoutSpy

        let firstLoad = try await service.loadAssets(for: "金毛")

        XCTAssertEqual(portraitSpy.callCount, 1)
        XCTAssertEqual(cutoutSpy.callCount, 1)
        XCTAssertEqual(ResourceDogAssetCache.portraitData(for: "金毛"), generatedPortrait)
        XCTAssertFalse(CutoutImageProcessor.needsCutoutRefresh(ResourceDogAssetCache.cutoutData(for: "金毛")))
        XCTAssertEqual(ResourceDogAssetCache.cutoutData(for: "金毛"), firstLoad.cutoutData)

        portraitSpy.callCount = 0
        cutoutSpy.callCount = 0

        let secondLoad = try await service.loadAssets(for: "金毛")

        XCTAssertEqual(secondLoad.portraitData, generatedPortrait)
        XCTAssertEqual(secondLoad.cutoutData, firstLoad.cutoutData)
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

        portraitSpy.callCount = 0
        cutoutSpy.callCount = 0

        let assets = try await service.loadAssets(for: "金毛")

        XCTAssertEqual(assets.portraitData, generatedPortrait)
        XCTAssertEqual(portraitSpy.callCount, 0)
        XCTAssertEqual(cutoutSpy.callCount, 0)
    }

    func testLoadPlanDoesNotClaimPortraitGenerationWhenBundleHasHandDrawn() throws {
        let dogFolder = tempRoot
            .appendingPathComponent("resource", isDirectory: true)
            .appendingPathComponent("雪纳瑞", isDirectory: true)
        try FileManager.default.createDirectory(at: dogFolder, withIntermediateDirectories: true)
        try makeTinyPNG().write(to: dogFolder.appendingPathComponent("hand-drawn-sit.png"))
        try makeTinyPNG().write(to: dogFolder.appendingPathComponent("foreground-dog-sit.png"))

        var service = ResourceDogService()
        service.catalog = catalog
        let plan = service.loadPlan(for: "雪纳瑞")

        XCTAssertFalse(plan.willGeneratePortrait)
        XCTAssertFalse(plan.willExtractCutout)
        XCTAssertFalse(plan.messages.contains(ResourceDogLoadStatus.generatingPortrait.message))
        XCTAssertTrue(plan.messages.contains(ResourceDogLoadStatus.readingPortrait.message))
    }

    @MainActor
    func testLoadAssetsReportsReadingNotGeneratingWhenBundleHasHandDrawn() async throws {
        let dogFolder = tempRoot
            .appendingPathComponent("resource", isDirectory: true)
            .appendingPathComponent("雪纳瑞", isDirectory: true)
        try FileManager.default.createDirectory(at: dogFolder, withIntermediateDirectories: true)
        try makeTinyPNG().write(to: dogFolder.appendingPathComponent("hand-drawn-sit.png"))
        try makeTinyPNG().write(to: dogFolder.appendingPathComponent("foreground-dog-sit.png"))

        var service = ResourceDogService()
        service.catalog = catalog
        service.portraitGenerator = portraitSpy
        service.cutoutExtractor = cutoutSpy

        var statuses: [ResourceDogLoadStatus] = []
        _ = try await service.loadAssets(for: "雪纳瑞") { status in
            statuses.append(status)
        }

        XCTAssertEqual(portraitSpy.callCount, 0)
        XCTAssertEqual(cutoutSpy.callCount, 0)
        XCTAssertEqual(
            statuses,
            [.readingResources, .readingPortrait, .readingCutout, .finishing]
        )
        XCTAssertFalse(statuses.contains(.generatingPortrait))
        XCTAssertFalse(statuses.contains(.extractingCutout))
    }

    @MainActor
    func testLoadAssetsReportsGeneratingPortraitWhenOnlyOriginalExists() async throws {
        portraitSpy.result = makeTinyPNG()
        cutoutSpy.result = makeTinyPNG()

        var service = ResourceDogService()
        service.catalog = catalog
        service.portraitGenerator = portraitSpy
        service.cutoutExtractor = cutoutSpy

        var statuses: [ResourceDogLoadStatus] = []
        _ = try await service.loadAssets(for: "金毛") { status in
            statuses.append(status)
        }

        XCTAssertEqual(portraitSpy.callCount, 1)
        XCTAssertTrue(statuses.contains(.generatingPortrait))
        XCTAssertTrue(statuses.contains(.extractingCutout))
        XCTAssertFalse(statuses.contains(.readingPortrait))
    }

    private func makeSoftCutoutPNG() throws -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 32))
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 32, height: 32))
            UIColor.brown.setFill()
            context.fill(CGRect(x: 10, y: 10, width: 12, height: 12))
        }
        return try CutoutImageProcessor.chromaKeyCutout(from: image)
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
