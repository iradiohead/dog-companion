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
}
