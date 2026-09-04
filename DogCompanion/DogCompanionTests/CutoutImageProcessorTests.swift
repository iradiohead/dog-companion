import XCTest
@testable import DogCompanion

final class CutoutImageProcessorTests: XCTestCase {
    func testNeedsCutoutRefreshWhenMissing() {
        XCTAssertTrue(CutoutImageProcessor.needsCutoutRefresh(nil))
    }

    func testStylePromptRequiresFlatWhiteBackground() {
        for style in StyleTemplate.allCases {
            XCTAssertTrue(style.prompt.contains("#FFFFFF"), "\(style) should request flat white background")
            XCTAssertTrue(style.negativePrompt.contains("纸张质感"))
        }
    }
}
