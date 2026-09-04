import XCTest
import UIKit
@testable import DogCompanion

final class CoatPaletteTests: XCTestCase {
    func testAllPalettesHaveFillAndBelly() {
        for palette in CoatPalette.allCases {
            XCTAssertGreaterThan(palette.fill.cgColor.numberOfComponents, 0)
            XCTAssertGreaterThan(palette.belly.cgColor.numberOfComponents, 0)
        }
        XCTAssertTrue(CoatPalette.spotted.hasSpots)
        XCTAssertFalse(CoatPalette.brown.hasSpots)
    }

    func testOrangeSquareSnapsToOrangeOrBrown() {
        let image = Self.solid(UIColor(red: 0.90, green: 0.45, blue: 0.12, alpha: 1))
        let snapped = CoatSampler.snap(from: image)
        XCTAssertTrue(snapped == .orange || snapped == .brown)
    }

    func testNearBlackSquareSnapsToBlack() {
        let image = Self.solid(UIColor(red: 0.08, green: 0.07, blue: 0.06, alpha: 1))
        XCTAssertEqual(CoatSampler.snap(from: image), .black)
    }

    func testPuppetPartsHaveFillAndLineNames() {
        XCTAssertEqual(PuppetPart.head.fillName, "puppet_fill_head")
        XCTAssertEqual(PuppetPart.eye.lineName, "puppet_line_eye")
        XCTAssertEqual(PuppetCatalog.drawOrder.count, PuppetPart.allCases.count)
        XCTAssertTrue(PuppetPart.eye.followsHead)
        XCTAssertTrue(PuppetPart.belly.followsBody)
    }

    func testFurnitureIsLayeredChairs() {
        XCTAssertEqual(SceneCatalog.furniture.count, 3)
        XCTAssertEqual(SceneCatalog.defaultFurniture.silhouette, .armchair)
        XCTAssertTrue(SceneCatalog.furniture.contains { $0.silhouette == .roundBack })
        XCTAssertTrue(SceneCatalog.furniture.contains { $0.silhouette == .sofa })
    }

    private static func solid(_ color: UIColor) -> UIImage {
        let size = CGSize(width: 32, height: 32)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
