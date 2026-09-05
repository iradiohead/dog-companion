import XCTest
@testable import DogCompanion

final class ResourceDogAssetCacheTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ResourceDogAssetCacheTests-\(UUID().uuidString)", isDirectory: true)
        ResourceDogAssetCache.rootDirectory = tempDirectory
    }

    override func tearDownWithError() throws {
        ResourceDogAssetCache.rootDirectory = nil
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    func testSaveAndLoadPortraitAndCutout() throws {
        let portrait = Data([0x01, 0x02])
        let cutout = Data([0x03, 0x04])

        let portraitURL = try ResourceDogAssetCache.savePortrait(portrait, for: "金毛")
        let cutoutURL = try ResourceDogAssetCache.saveCutout(cutout, for: "金毛")

        XCTAssertTrue(FileManager.default.fileExists(atPath: portraitURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: cutoutURL.path))
        XCTAssertEqual(ResourceDogAssetCache.portraitData(for: "金毛"), portrait)
        XCTAssertEqual(ResourceDogAssetCache.cutoutData(for: "金毛"), cutout)
        XCTAssertTrue(cutoutURL.lastPathComponent.contains("foreground-dog-v3"))
    }

    func testMissingCacheReturnsNil() {
        XCTAssertNil(ResourceDogAssetCache.portraitData(for: "不存在"))
        XCTAssertNil(ResourceDogAssetCache.cutoutData(for: "不存在"))
    }

    func testDirectoryURLUsesOverrideRoot() {
        XCTAssertEqual(ResourceDogAssetCache.directoryURL(), tempDirectory)
    }

    func testLogDirectoryOnLaunchCreatesFolderOnDisk() {
        ResourceDogAssetCache.logDirectoryOnLaunch()

        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.path))
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: tempDirectory.appendingPathComponent(".keep").path
            )
        )
    }
}
