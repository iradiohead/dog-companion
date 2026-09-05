import XCTest
@testable import DogCompanion

final class ResourceDogCatalogTests: XCTestCase {
    private var tempRoot: URL!
    private var catalog: ResourceDogCatalog!

    override func setUpWithError() throws {
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("ResourceDogCatalogTests-\(UUID().uuidString)", isDirectory: true)
        let resourceRoot = tempRoot.appendingPathComponent("resource", isDirectory: true)
        let dogFolder = resourceRoot.appendingPathComponent("雪纳瑞", isDirectory: true)
        try FileManager.default.createDirectory(at: dogFolder, withIntermediateDirectories: true)

        let handDrawn = dogFolder.appendingPathComponent("hand-drawn-sit-old.png")
        let handDrawnNew = dogFolder.appendingPathComponent("hand-drawn-sit-new.png")
        let foreground = dogFolder.appendingPathComponent("foreground-dog-sit-a.png")
        let original = dogFolder.appendingPathComponent("original.jpg")
        try Data([0x01]).write(to: handDrawn)
        try Data([0x02]).write(to: handDrawnNew)
        try Data([0x03]).write(to: foreground)
        try Data([0x04]).write(to: original)

        catalog = ResourceDogCatalog(resourceRootOverride: resourceRoot)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempRoot)
    }

    func testAvailableDogNamesListsFolders() {
        XCTAssertEqual(catalog.availableDogNames(), ["雪纳瑞"])
    }

    func testLatestFilePicksLexicographicallyLatestName() throws {
        let folder = try catalog.folderURL(for: "雪纳瑞")
        let latestHandDrawn = catalog.latestFile(in: folder, prefix: "hand-drawn")
        XCTAssertEqual(latestHandDrawn?.lastPathComponent, "hand-drawn-sit-new.png")
    }

    func testOriginalImageURLPrefersFixedOriginalName() throws {
        let folder = try catalog.folderURL(for: "雪纳瑞")
        let original = catalog.originalImageURL(in: folder)
        XCTAssertEqual(original?.lastPathComponent, "original.jpg")
    }

    func testOriginalImageURLAcceptsArbitraryFileName() throws {
        let resourceRoot = tempRoot.appendingPathComponent("resource", isDirectory: true)
        let dogFolder = resourceRoot.appendingPathComponent("金毛", isDirectory: true)
        try FileManager.default.createDirectory(at: dogFolder, withIntermediateDirectories: true)
        let photo = dogFolder.appendingPathComponent("金毛寻回犬.jpg")
        try Data([0x05]).write(to: photo)

        let folder = try catalog.folderURL(for: "金毛")
        let original = catalog.originalImageURL(in: folder)
        XCTAssertEqual(original?.lastPathComponent, "金毛寻回犬.jpg")
    }

    func testOriginalImageURLIgnoresHandDrawnAndForeground() throws {
        let resourceRoot = tempRoot.appendingPathComponent("resource", isDirectory: true)
        let dogFolder = resourceRoot.appendingPathComponent("测试犬", isDirectory: true)
        try FileManager.default.createDirectory(at: dogFolder, withIntermediateDirectories: true)
        try Data([0x01]).write(to: dogFolder.appendingPathComponent("hand-drawn-sit.png"))
        try Data([0x02]).write(to: dogFolder.appendingPathComponent("foreground-dog-sit.png"))
        try Data([0x03]).write(to: dogFolder.appendingPathComponent("我的狗.jpg"))

        let folder = try catalog.folderURL(for: "测试犬")
        XCTAssertEqual(catalog.originalImageURL(in: folder)?.lastPathComponent, "我的狗.jpg")
    }
}
