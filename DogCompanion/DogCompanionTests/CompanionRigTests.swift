import XCTest
import UIKit
@testable import DogCompanion

final class CompanionRigTests: XCTestCase {
    func testSittingHeadAndTailUseSine() {
        let rest = CompanionRigMotion.transform(state: .sitting, time: 0)
        let headPeak = CompanionRigMotion.transform(state: .sitting, time: Double.pi / 2)
        let tailPeak = CompanionRigMotion.transform(state: .sitting, time: Double.pi / 4)
        XCTAssertEqual(rest.headY, 0, accuracy: 0.01)
        XCTAssertGreaterThan(headPeak.headY, 4)
        XCTAssertGreaterThan(abs(tailPeak.tailRotation), 0.1)
        XCTAssertGreaterThan(headPeak.bodyY, 1)
    }

    func testJumpCrouchDipsTheHead() {
        let pose = CompanionRigMotion.transform(
            state: .jumping,
            time: PosePlayback.crouchStart + PosePlayback.crouchDuration
        )
        XCTAssertLessThan(pose.headY, -3)
        XCTAssertLessThan(pose.bodyY, -2)
    }

    func testJumpApexTucksTheLegs() {
        let pose = CompanionRigMotion.transform(
            state: .jumping,
            time: PosePlayback.jumpStart + PosePlayback.jumpDuration * 0.5
        )
        XCTAssertLessThan(pose.frontLegRotation, -0.1)
        XCTAssertGreaterThan(pose.tailRotation, 0.1)
    }

    func testJumpSettlesToRest() {
        let pose = CompanionRigMotion.transform(state: .jumping, time: PosePlayback.runningInDuration)
        XCTAssertEqual(pose.headY, 0, accuracy: 0.2)
        XCTAssertEqual(pose.frontLegRotation, 0, accuracy: 0.05)
    }

    func testWalkingSwingsLegsOpposite() {
        let pose = CompanionRigMotion.transform(state: .walking, time: Double.pi / 2 / 3.2)
        XCTAssertGreaterThan(abs(pose.frontLegRotation - pose.backLegRotation), 0.1)
    }

    func testIdleMapsToSittingAndRunInStartsRunning() {
        XCTAssertEqual(CompanionRigMotion.rigState(from: .idle), .sitting)
        XCTAssertEqual(CompanionRigMotion.rigState(from: .runningIn, elapsed: 0.2), .running)
        XCTAssertEqual(
            CompanionRigMotion.rigState(from: .runningIn, elapsed: PosePlayback.runDuration + 0.05),
            .jumping
        )
        XCTAssertEqual(CompanionRigMotion.rigState(from: .celebrating), .sitting)
    }

    func testSlicerSplitsBlobIntoHeadBodyAndLegs() throws {
        let blob = Self.makeSitBlob()
        let layers = try XCTUnwrap(CompanionLayerSlicer.slice(blob))
        XCTAssertNotNil(layers.image(for: .head))
        XCTAssertNotNil(layers.image(for: .body))
        XCTAssertGreaterThanOrEqual(layers.images.count, 3)

        let head = try XCTUnwrap(layers.image(for: .head))
        let body = try XCTUnwrap(layers.image(for: .body))
        XCTAssertGreaterThan(Self.opaqueCount(head), 8)
        XCTAssertGreaterThan(Self.opaqueCount(body), 8)
        XCTAssertGreaterThan(
            CompanionLayerSlicer.weight(for: .head, nx: 0.5, ny: 0.12, tailOnLeft: true),
            0.4
        )
        XCTAssertLessThan(
            CompanionLayerSlicer.weight(for: .head, nx: 0.5, ny: 0.82, tailOnLeft: true),
            0.05
        )
        XCTAssertGreaterThan(
            CompanionLayerSlicer.weight(for: .body, nx: 0.5, ny: 0.62, tailOnLeft: true),
            0.5
        )
        XCTAssertLessThan(
            CompanionLayerSlicer.weight(for: .frontLeg, nx: 0.5, ny: 0.62, tailOnLeft: true),
            0.08
        )
        XCTAssertGreaterThan(
            CompanionLayerSlicer.weight(for: .tail, nx: 0.08, ny: 0.7, tailOnLeft: true),
            0.2
        )
    }

    private static func makeSitBlob() -> UIImage {
        let size = CGSize(width: 48, height: 72)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            UIColor(red: 0.82, green: 0.55, blue: 0.32, alpha: 1).setFill()
            UIBezierPath(roundedRect: CGRect(x: 12, y: 6, width: 24, height: 60), cornerRadius: 10).fill()
        }
    }

    private static func opaqueCount(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        let width = cgImage.width
        let height = cgImage.height
        var data = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return 0
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        var count = 0
        for index in stride(from: 3, to: data.count, by: 4) where data[index] > 20 {
            count += 1
        }
        return count
    }
}
