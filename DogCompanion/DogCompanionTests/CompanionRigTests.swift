import XCTest
import UIKit
@testable import DogCompanion

final class CompanionRigTests: XCTestCase {
    func testSittingHeadAndTailUseSine() {
        let rest = CompanionRigMotion.transform(state: .sitting, time: 0)
        let headPeak = CompanionRigMotion.transform(state: .sitting, time: Double.pi / 2)
        let tailPeak = CompanionRigMotion.transform(state: .sitting, time: Double.pi / (2.0 * 0.7))
        XCTAssertEqual(rest.headY, 0, accuracy: 0.01)
        XCTAssertGreaterThan(headPeak.headY, 2.5)
        XCTAssertLessThan(headPeak.headY, 6)
        XCTAssertGreaterThan(abs(tailPeak.tailRotation), 0.03)
        XCTAssertLessThan(abs(tailPeak.tailRotation), 0.16)
        XCTAssertGreaterThan(headPeak.bodyY, 0.6)
        XCTAssertLessThan(headPeak.bodyY, 2.5)
        XCTAssertGreaterThan(abs(headPeak.headRotation), 0.02)
        XCTAssertLessThan(headPeak.bodyScaleY, 1.03)
    }

    func testJumpKeepsPartsStill() {
        let crouch = CompanionRigMotion.transform(
            state: .jumping,
            time: PosePlayback.crouchDuration
        )
        let apex = CompanionRigMotion.transform(
            state: .jumping,
            time: PosePlayback.jumpStart + PosePlayback.jumpDuration * 0.5
        )
        XCTAssertEqual(crouch, .identity)
        XCTAssertEqual(apex, .identity)
    }

    func testJumpSettlesToRest() {
        let pose = CompanionRigMotion.transform(state: .jumping, time: PosePlayback.runningInDuration)
        XCTAssertEqual(pose.headY, 0, accuracy: 0.2)
        XCTAssertEqual(pose.frontLegRotation, 0, accuracy: 0.05)
        XCTAssertEqual(pose.bodyScaleX, 1, accuracy: 0.05)
    }

    func testRunningPoseSwingsLegs() {
        let run = CompanionRigMotion.transform(state: .running, time: 0.2)
        XCTAssertGreaterThan(abs(run.frontLegRotation), 0.1)
        XCTAssertGreaterThan(abs(run.frontLegRotation - run.backLegRotation), 0.1)
    }

    func testWalkingSwingsLegsOpposite() {
        let pose = CompanionRigMotion.transform(state: .walking, time: Double.pi / 2 / 3.2)
        XCTAssertGreaterThan(abs(pose.frontLegRotation - pose.backLegRotation), 0.1)
    }

    func testIdleMapsToSittingAndHopFreezesParts() {
        XCTAssertEqual(CompanionRigMotion.rigState(from: .idle), .sitting)
        XCTAssertEqual(CompanionRigMotion.rigState(from: .runningIn, elapsed: 0.2), .jumping)
        XCTAssertEqual(
            CompanionRigMotion.rigState(from: .runningIn, elapsed: PosePlayback.jumpStart),
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
            CompanionLayerSlicer.weight(for: .body, nx: 0.5, ny: 0.12, tailOnLeft: true),
            0.08
        )
        XCTAssertLessThan(
            CompanionLayerSlicer.weight(for: .body, nx: 0.5, ny: 0.22, tailOnLeft: true),
            0.08
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
        XCTAssertLessThan(Self.opaqueCountInTopQuarter(body), Self.opaqueCountInTopQuarter(head))
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

    private static func opaqueCountInTopQuarter(_ image: UIImage) -> Int {
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
        let maxY = max(1, height / 4)
        var count = 0
        for y in 0..<maxY {
            for x in 0..<width {
                let alpha = data[(y * width + x) * 4 + 3]
                if alpha > 20 {
                    count += 1
                }
            }
        }
        return count
    }
}
