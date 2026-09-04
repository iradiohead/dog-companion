import XCTest
import UIKit
@testable import DogCompanion

final class CompanionRigTests: XCTestCase {
    func testSittingHeadAndTailUseSine() {
        let rest = CompanionRigMotion.transform(state: .sitting, time: 0)
        let headPeak = CompanionRigMotion.transform(state: .sitting, time: Double.pi / 2)
        let tailPeak = CompanionRigMotion.transform(state: .sitting, time: Double.pi / (2.0 * 0.7))
        XCTAssertEqual(rest.headY, 0, accuracy: 0.01)
        XCTAssertGreaterThan(headPeak.headY, 3)
        XCTAssertLessThan(headPeak.headY, 5)
        XCTAssertGreaterThan(abs(tailPeak.tailRotation), 0.04)
        XCTAssertLessThan(abs(tailPeak.tailRotation), 0.18)
        XCTAssertGreaterThan(headPeak.bodyY, 1.2)
        XCTAssertLessThan(headPeak.bodyY, 2.4)
        XCTAssertGreaterThan(abs(headPeak.headRotation), 0.03)
        XCTAssertGreaterThan(headPeak.bodyScaleY, 1.008)
        XCTAssertGreaterThan(abs(headPeak.frontLegRotation), 0.02)
    }

    func testClimbMovesHeadLegsAndTail() {
        let crouch = CompanionRigMotion.transform(
            state: .jumping,
            time: PosePlayback.crouchDuration
        )
        let apex = CompanionRigMotion.transform(
            state: .jumping,
            time: PosePlayback.jumpStart + PosePlayback.jumpDuration * 0.35
        )
        XCTAssertLessThan(crouch.headY, -8)
        XCTAssertLessThan(crouch.bodyY, -4)
        XCTAssertGreaterThan(abs(crouch.frontLegRotation), 0.2)
        XCTAssertLessThan(crouch.tailRotation, -0.1)
        XCTAssertLessThan(apex.frontLegRotation, -0.3)
        XCTAssertGreaterThan(apex.tailRotation, 0.2)
        XCTAssertGreaterThan(apex.bodyScaleY, 1.05)
    }

    func testJumpSettlesToRest() {
        let pose = CompanionRigMotion.transform(state: .jumping, time: PosePlayback.climbDuration)
        XCTAssertEqual(pose.headY, 0, accuracy: 0.2)
        XCTAssertEqual(pose.frontLegRotation, 0, accuracy: 0.05)
        XCTAssertEqual(pose.bodyScaleX, 1, accuracy: 0.05)
    }

    func testRunningPoseSwingsLegs() {
        let run = CompanionRigMotion.transform(state: .running, time: 0.2)
        XCTAssertGreaterThan(abs(run.frontLegRotation), 0.1)
        XCTAssertGreaterThan(abs(run.frontLegRotation - run.backLegRotation), 0.1)
    }

    func testRunInFacesRightThenTurnsForward() {
        let midRun = PosePlayback.travel(state: .runningIn, elapsed: 0.3)
        XCTAssertLessThan(midRun.facingScaleX, 0)

        let arrived = PosePlayback.travel(
            state: .runningIn,
            elapsed: PosePlayback.runDuration + PosePlayback.brakeDuration * 0.5
        )
        XCTAssertGreaterThan(arrived.facingScaleX, 0)

        let settled = PosePlayback.travel(
            state: .runningIn,
            elapsed: PosePlayback.runningInDuration
        )
        XCTAssertEqual(settled.facingScaleX, 1, accuracy: 0.01)
        XCTAssertEqual(settled.x, 0, accuracy: 2)
    }

    func testRunInUsesOwnerFlipbookGaitWhileMoving() {
        let stepA = CompanionRigMotion.transform(
            motion: .runningIn,
            elapsed: 0.2,
            usesRunFlipbook: true
        )
        let stepB = CompanionRigMotion.transform(
            motion: .runningIn,
            elapsed: 0.2 + Double.pi / 11.0,
            usesRunFlipbook: true
        )
        XCTAssertEqual(stepA.frontLegX, 0, accuracy: 0.01)
        XCTAssertLessThan(stepA.lean, -0.02)
        XCTAssertGreaterThan(stepA.bodyY, 0.5)
        XCTAssertGreaterThan(abs(stepA.bodyY - stepB.bodyY), 0.1)
    }

    func testRunInCutoutSettlesWithoutCrabWalk() {
        let stepA = CompanionRigMotion.transform(
            motion: .runningIn,
            elapsed: PosePlayback.runDuration + 0.05
        )
        let stepB = CompanionRigMotion.transform(
            motion: .runningIn,
            elapsed: PosePlayback.runDuration + 0.05 + Double.pi / 11.0
        )
        XCTAssertEqual(stepA.frontLegX, 0, accuracy: 0.01)
        XCTAssertEqual(stepA.backLegX, 0, accuracy: 0.01)
        XCTAssertEqual(stepA.frontLegRotation, 0, accuracy: 0.01)
        XCTAssertEqual(stepA.backLegRotation, 0, accuracy: 0.01)
        XCTAssertGreaterThan(abs(stepA.frontLegY), 1.5)
        XCTAssertGreaterThan(abs(stepB.frontLegY), 1.5)
        XCTAssertLessThan(stepA.frontLegY * stepB.frontLegY, 0)
    }

    func testRunInFacingFrontWhenNoFlipbook() {
        let run = CompanionRigMotion.transform(motion: .runningIn, elapsed: 0.2, usesRunFlipbook: false)
        XCTAssertLessThan(run.headRotation, -0.08)
        XCTAssertLessThan(run.headX, -4)
        XCTAssertGreaterThan(abs(run.frontLegY), 1.5)
    }

    func testRunInBlendsIntoSittingAfterTheGallop() {
        let midBrake = CompanionRigMotion.transform(
            motion: .runningIn,
            elapsed: PosePlayback.runDuration + 0.12
        )
        XCTAssertGreaterThan(midBrake.bodyY, 0.1)
        let sitting = CompanionRigMotion.transform(
            state: .sitting,
            time: PosePlayback.runningInDuration
        )
        let settled = CompanionRigMotion.transform(
            motion: .runningIn,
            elapsed: PosePlayback.runningInDuration
        )
        XCTAssertEqual(settled.lean, sitting.lean, accuracy: 0.02)
        XCTAssertEqual(settled.headY, sitting.headY, accuracy: 0.2)
    }

    func testWalkingSwingsLegsOpposite() {
        let pose = CompanionRigMotion.transform(state: .walking, time: Double.pi / 2 / 3.2)
        XCTAssertGreaterThan(abs(pose.frontLegRotation - pose.backLegRotation), 0.1)
    }

    func testIdleMapsToSittingAndRunInKeepsSitRig() {
        XCTAssertEqual(CompanionRigMotion.rigState(from: .idle), .sitting)
        XCTAssertEqual(CompanionRigMotion.rigState(from: .runningIn, elapsed: 0.2), .sitting)
        XCTAssertEqual(
            CompanionRigMotion.rigState(from: .runningIn, elapsed: PosePlayback.runDuration + 0.01),
            .sitting
        )
        XCTAssertEqual(CompanionRigMotion.rigState(from: .celebrating), .sitting)
    }

    func testIdleBlinkClosesTheEye() {
        XCTAssertEqual(CompanionRigMotion.eyeScale(time: 0), 1, accuracy: 0.01)
        XCTAssertLessThan(CompanionRigMotion.eyeScale(time: 3.35), 0.3)
    }

    func testSlicerSplitsBlobIntoHeadBodyAndLegs() throws {
        let blob = Self.makeSitBlob()
        let layers = try XCTUnwrap(CompanionLayerSlicer.slice(blob))
        XCTAssertNotNil(layers.image(for: .head))
        XCTAssertNotNil(layers.image(for: .body))
        XCTAssertNotNil(layers.image(for: .tail))
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
            CompanionLayerSlicer.weight(for: .backLeg, nx: 0.08, ny: 0.82, tailOnLeft: true),
            0.2
        )
        XCTAssertGreaterThan(
            CompanionLayerSlicer.weight(for: .backLeg, nx: 0.92, ny: 0.82, tailOnLeft: false),
            0.2
        )
        XCTAssertGreaterThan(
            CompanionLayerSlicer.weight(for: .tail, nx: 0.08, ny: 0.7, tailOnLeft: true),
            0.2
        )
        XCTAssertLessThan(
            CompanionLayerSlicer.weight(for: .body, nx: 0.08, ny: 0.7, tailOnLeft: true),
            0.12,
            "Body must not keep a second frozen tail beside the wagging tail layer"
        )
        XCTAssertLessThan(
            CompanionLayerSlicer.weight(for: .body, nx: 0.92, ny: 0.7, tailOnLeft: false),
            0.12
        )
        XCTAssertGreaterThan(
            CompanionLayerSlicer.weight(for: .body, nx: 0.32, ny: 0.62, tailOnLeft: true),
            0.2,
            "Rump stays on the body so the tail joint does not open a hole"
        )
        XCTAssertGreaterThan(
            CompanionLayerSlicer.weight(for: .head, nx: 0.04, ny: 0.12, tailOnLeft: true),
            0.35,
            "Ears on the left of the sit cutout must stay on the head layer"
        )
        XCTAssertGreaterThan(
            CompanionLayerSlicer.weight(for: .head, nx: 0.96, ny: 0.12, tailOnLeft: true),
            0.35,
            "Ears on the right of the sit cutout must stay on the head layer"
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
