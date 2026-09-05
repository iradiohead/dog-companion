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

        try Data([0x01]).write(to: dogFolder.appendingPathComponent("hand-drawn-sit-old.png"))
        try Data([0x02]).write(to: dogFolder.appendingPathComponent("hand-drawn-sit-new.png"))
        try Data([0x03]).write(to: dogFolder.appendingPathComponent("foreground-dog-sit-a.png"))
        try Data([0x04]).write(to: dogFolder.appendingPathComponent("original.jpg"))

        catalog = ResourceDogCatalog(resourceRootOverride: resourceRoot)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempRoot)
    }

    func testAvailableDogNamesListsFolders() {
        XCTAssertEqual(catalog.availableDogNames(), ["雪纳瑞"])
    }

    func testFolderContentsPicksLatestHandDrawn() throws {
        let contents = try catalog.folderContents(for: "雪纳瑞")
        XCTAssertEqual(contents.handDrawnURL?.lastPathComponent, "hand-drawn-sit-new.png")
        XCTAssertEqual(contents.foregroundURL?.lastPathComponent, "foreground-dog-sit-a.png")
        XCTAssertEqual(contents.originalURL?.lastPathComponent, "original.jpg")
    }

    func testOriginalURLAcceptsArbitraryFileName() throws {
        let resourceRoot = tempRoot.appendingPathComponent("resource", isDirectory: true)
        let dogFolder = resourceRoot.appendingPathComponent("金毛", isDirectory: true)
        try FileManager.default.createDirectory(at: dogFolder, withIntermediateDirectories: true)
        try Data([0x05]).write(to: dogFolder.appendingPathComponent("金毛寻回犬.jpg"))

        let contents = try catalog.folderContents(for: "金毛")
        XCTAssertEqual(contents.originalURL?.lastPathComponent, "金毛寻回犬.jpg")
    }

    func testOriginalURLOnlyUsesNonGeneratedFiles() throws {
        let resourceRoot = tempRoot.appendingPathComponent("resource", isDirectory: true)
        let dogFolder = resourceRoot.appendingPathComponent("测试犬", isDirectory: true)
        try FileManager.default.createDirectory(at: dogFolder, withIntermediateDirectories: true)
        try Data([0x01]).write(to: dogFolder.appendingPathComponent("hand-drawn-sit.png"))
        try Data([0x02]).write(to: dogFolder.appendingPathComponent("foreground-dog-sit.png"))
        try Data([0x03]).write(to: dogFolder.appendingPathComponent("我的狗.jpg"))

        let contents = try catalog.folderContents(for: "测试犬")
        XCTAssertEqual(contents.originalURL?.lastPathComponent, "我的狗.jpg")
    }

    func testPreviewImageURLPrefersHandDrawn() throws {
        let contents = try catalog.folderContents(for: "雪纳瑞")
        XCTAssertEqual(catalog.previewImageURL(for: "雪纳瑞"), contents.handDrawnURL)
    }
}
