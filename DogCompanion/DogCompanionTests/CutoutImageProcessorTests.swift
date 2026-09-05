import XCTest
import UIKit
@testable import DogCompanion

final class CutoutImageProcessorTests: XCTestCase {
    func testNeedsCutoutRefreshWhenMissing() {
        XCTAssertTrue(CutoutImageProcessor.needsCutoutRefresh(nil))
    }

    func testStylePromptRequiresFlatWhiteBackground() {
        let style = StyleTemplate.default
        XCTAssertTrue(style.prompt.contains("#FFFFFF"))
        XCTAssertTrue(style.prompt.contains("一眼能认出"))
        XCTAssertTrue(style.prompt.contains("手绘"))
        XCTAssertTrue(style.negativePrompt.contains("纸张质感"))
        XCTAssertFalse(style.prompt.contains("共用的圆滚"))
    }

    func testChromaKeyMakesWhiteBackgroundTransparent() throws {
        let image = makeDogOnWhiteBackground()
        let cutout = try CutoutImageProcessor.chromaKeyCutout(from: image)

        XCTAssertTrue(CutoutImageProcessor.hasMeaningfulTransparency(in: cutout))
        XCTAssertFalse(CutoutImageProcessor.needsCutoutRefresh(cutout))

        guard let cutoutImage = UIImage(data: cutout),
              let cgImage = cutoutImage.cgImage else {
            return XCTFail("Cutout PNG could not be decoded")
        }
        XCTAssertGreaterThan(cgImage.width, 0)
        XCTAssertLessThan(cgImage.width, 32)
    }

    func testOpaqueWhiteImageNeedsRefresh() throws {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
        guard let data = image.pngData() else {
            return XCTFail("Failed to encode white image")
        }
        XCTAssertTrue(CutoutImageProcessor.needsCutoutRefresh(data))
    }

    private func makeDogOnWhiteBackground() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 32))
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 32, height: 32))
            UIColor.brown.setFill()
            context.fill(CGRect(x: 10, y: 10, width: 12, height: 12))
        }
    }
}
