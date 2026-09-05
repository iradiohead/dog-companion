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

    func testOpaqueCutoutSolidifiesSoftPixels() throws {
        let image = makeDogOnWhiteBackground()
        let soft = try CutoutImageProcessor.chromaKeyCutout(from: image)
        let opaque = try CutoutImageProcessor.opaqueCutout(from: soft)
        XCTAssertTrue(CutoutImageProcessor.hasMeaningfulTransparency(in: opaque))
        XCTAssertFalse(CutoutImageProcessor.needsCutoutRefresh(opaque))
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

    func testRefineCutoutCanPunchHolesInLightFur() throws {
        let visionLike = try makeVisionLikeLightDogCutout()
        let refined = try CutoutImageProcessor.refineCutout(from: UIImage(data: visionLike)!)
        let opaque = try CutoutImageProcessor.opaqueCutout(from: visionLike)

        XCTAssertGreaterThan(countOpaquePixels(in: opaque), countOpaquePixels(in: refined))
    }

    func testVisionLikeLightFurNeedsRefreshBeforeOpaque() throws {
        let visionLike = try makeVisionLikeLightDogCutout()
        XCTAssertTrue(CutoutImageProcessor.needsCutoutRefresh(visionLike))
        let opaque = try CutoutImageProcessor.opaqueCutout(from: visionLike)
        XCTAssertFalse(CutoutImageProcessor.needsCutoutRefresh(opaque))
    }

    private func makeVisionLikeLightDogCutout() throws -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 32))
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 32, height: 32))
            UIColor(red: 0.95, green: 0.88, blue: 0.72, alpha: 1).setFill()
            context.fill(CGRect(x: 8, y: 8, width: 16, height: 16))
        }
        guard var cgImage = image.cgImage else {
            throw XCTSkip("Failed to build test image")
        }
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = 4 * width
        var pixelData = [UInt8](repeating: 0, count: height * bytesPerRow)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        guard let ctx = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw XCTSkip("Failed to create bitmap context")
        }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * 4
                let insideDog = x >= 8 && x < 24 && y >= 8 && y < 24
                pixelData[offset + 3] = insideDog ? 220 : 0
            }
        }
        guard let masked = ctx.makeImage(), let data = UIImage(cgImage: masked).pngData() else {
            throw XCTSkip("Failed to encode masked image")
        }
        return data
    }

    private func countOpaquePixels(in data: Data) -> Int {
        guard let image = UIImage(data: data),
              let cgImage = image.cgImage,
              let provider = cgImage.dataProvider,
              let raw = provider.data,
              let bytes = CFDataGetBytePtr(raw) else {
            return 0
        }
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        guard bytesPerPixel == 4 else { return 0 }
        var count = 0
        let length = CFDataGetLength(raw)
        for offset in stride(from: 3, to: length, by: 4) {
            if bytes[offset] > 200 { count += 1 }
        }
        return count
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
