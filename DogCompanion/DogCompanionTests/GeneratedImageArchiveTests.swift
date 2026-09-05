import XCTest
@testable import DogCompanion

final class GeneratedImageArchiveTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("GeneratedImageArchiveTests-\(UUID().uuidString)", isDirectory: true)
        GeneratedImageArchive.rootDirectory = tempDirectory
    }

    override func tearDownWithError() throws {
        GeneratedImageArchive.rootDirectory = nil
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    func testSavePortraitWritesPNGToArchiveDirectory() throws {
        let data = Data([0x89, 0x50, 0x4E, 0x47])
        let saved = try GeneratedImageArchive.savePortrait(data, pose: .sit)

        XCTAssertTrue(saved.path.hasSuffix(".png"))
        XCTAssertTrue(saved.path.contains("hand-drawn-sit"))
        XCTAssertEqual(try Data(contentsOf: saved), data)
    }

    func testSaveForegroundCutoutUsesDedicatedPrefix() throws {
        let data = Data([0x01, 0x02, 0x03])
        let saved = try GeneratedImageArchive.saveForegroundCutout(data, pose: .sit)

        XCTAssertTrue(saved.path.contains("foreground-dog-sit"))
        XCTAssertEqual(try Data(contentsOf: saved), data)
    }

    func testDefaultArchiveDirectoryUsesDogCompanionFolder() {
        let directory = GeneratedImageArchive.defaultArchiveDirectory()
        XCTAssertTrue(directory.path.contains("DogCompanion"))
        XCTAssertTrue(directory.path.hasSuffix("hand-drawn-portraits"))
        #if targetEnvironment(macCatalyst)
        XCTAssertTrue(directory.path.contains("/Library/"))
        #endif
    }
}
