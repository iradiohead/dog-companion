import XCTest
import UIKit
@testable import DogCompanion

/// End-to-end coverage for the dog run-in entrance: trajectory, facing, rig, and flipbook.
final class RunInEntranceTests: XCTestCase {
    // MARK: - Timeline phases

    func testPhaseTimingConstants() {
        XCTAssertEqual(PosePlayback.runDuration, 0.92, accuracy: 0.001)
        XCTAssertEqual(PosePlayback.brakeDuration, 0.20, accuracy: 0.001)
        XCTAssertEqual(PosePlayback.settleDuration, 0.14, accuracy: 0.001)
        XCTAssertEqual(PosePlayback.brakeStart, PosePlayback.runDuration, accuracy: 0.001)
        XCTAssertEqual(
            PosePlayback.runningInDuration,
            PosePlayback.runDuration + PosePlayback.brakeDuration + PosePlayback.settleDuration,
            accuracy: 0.001
        )
    }

    func testUsesSitPoseThroughoutEntrance() {
        for elapsed in sampleTimes() {
            XCTAssertEqual(
                PosePlayback.pose(state: .runningIn, elapsed: elapsed),
                .sit,
                "Expected sit art at elapsed \(elapsed)"
            )
        }
    }

    func testStartsOffScreenLeft() {
        let start = PosePlayback.travel(state: .runningIn, elapsed: 0)
        XCTAssertLessThan(start.x, -PosePlayback.runDistance * 0.85)
        XCTAssertEqual(start.y, 0, accuracy: 12)
    }

    func testOpacityStaysOpaqueThroughoutRunIn() {
        for elapsed in stride(from: 0, through: PosePlayback.runningInDuration, by: 0.05) {
            let travel = PosePlayback.travel(state: .runningIn, elapsed: elapsed)
            XCTAssertEqual(travel.opacity, 1, accuracy: 0.001, "at \(elapsed)s")
            XCTAssertEqual(PosePlayback.runInOpacity(elapsed: elapsed), 1, accuracy: 0.001)
        }
    }

    func testIdleAfterRunInIsFullyOpaque() {
        let idle = PosePlayback.travel(state: .idle, elapsed: 0)
        XCTAssertEqual(idle.opacity, 1, accuracy: 0.001)
    }

    // MARK: - Horizontal run

    func testHorizontalPositionIncreasesMonotonicallyDuringRun() {
        var previousX = PosePlayback.travel(state: .runningIn, elapsed: 0).x
        var elapsed: TimeInterval = 1.0 / 60.0
        while elapsed < PosePlayback.runDuration {
            let travel = PosePlayback.travel(state: .runningIn, elapsed: elapsed)
            XCTAssertGreaterThan(travel.x, previousX)
            previousX = travel.x
            elapsed += 1.0 / 60.0
        }
    }

    func testStartsFacingRightWhileRunning() {
        for elapsed in stride(from: 0.05, through: PosePlayback.runDuration - 0.02, by: 0.08) {
            let travel = PosePlayback.travel(state: .runningIn, elapsed: elapsed)
            XCTAssertLessThan(
                travel.facingScaleX,
                0,
                "Dog should face right while galloping at \(elapsed)s"
            )
        }
    }

    func testReachesCenterAtEndOfRunPhase() {
        let end = PosePlayback.travel(state: .runningIn, elapsed: PosePlayback.runDuration)
        XCTAssertEqual(end.x, 0, accuracy: 4)
    }

    func testResponsiveRunDistanceScalesStartPosition() {
        let narrow = PosePlayback.travel(state: .runningIn, elapsed: 0.05, runDistance: 96)
        let wide = PosePlayback.travel(state: .runningIn, elapsed: 0.05, runDistance: 168)
        XCTAssertLessThan(narrow.x, wide.x)
        XCTAssertGreaterThan(abs(narrow.x), 70)
        XCTAssertLessThan(abs(wide.x), abs(narrow.x) * 1.2)
    }

    // MARK: - Brake and settle

    func testFacingTurnsForwardDuringBrake() {
        let stillRight = PosePlayback.travel(
            state: .runningIn,
            elapsed: PosePlayback.runDuration + 0.02
        )
        let turned = PosePlayback.travel(
            state: .runningIn,
            elapsed: PosePlayback.runDuration + PosePlayback.brakeDuration * 0.6
        )
        XCTAssertLessThan(stillRight.facingScaleX, 0)
        XCTAssertGreaterThan(turned.facingScaleX, 0)
    }

    func testBrakePhaseKeepsXAtZero() {
        for elapsed in stride(
            from: PosePlayback.runDuration,
            through: PosePlayback.runningInDuration,
            by: 0.04
        ) {
            let travel = PosePlayback.travel(state: .runningIn, elapsed: elapsed)
            XCTAssertEqual(travel.x, 0, accuracy: 2, "x drift during brake/settle at \(elapsed)s")
        }
    }

    func testSettlesToNeutralAtEnd() {
        let end = PosePlayback.travel(state: .runningIn, elapsed: PosePlayback.runningInDuration)
        XCTAssertEqual(end.x, 0, accuracy: 2)
        XCTAssertEqual(end.y, 0, accuracy: 3)
        XCTAssertEqual(end.facingScaleX, 1, accuracy: 0.02)
        XCTAssertEqual(end.scaleX, 1, accuracy: 0.05)
        XCTAssertEqual(end.scaleY, 1, accuracy: 0.05)
        XCTAssertEqual(end.rotationDegrees, 0, accuracy: 2)
        XCTAssertEqual(end.opacity, 1, accuracy: 0.02)
    }

    func testBrakeRotationEasesTowardZero() {
        let brake = PosePlayback.travel(
            state: .runningIn,
            elapsed: PosePlayback.brakeStart + 0.08
        )
        let settled = PosePlayback.travel(
            state: .runningIn,
            elapsed: PosePlayback.runningInDuration
        )
        XCTAssertLessThan(abs(brake.rotationDegrees), 6)
        XCTAssertEqual(settled.rotationDegrees, 0, accuracy: 1.5)
    }

    // MARK: - Bounce and shadow

    func testVerticalBounceWhileRunning() {
        var sawLift = false
        var elapsed: TimeInterval = 0.05
        while elapsed < PosePlayback.runDuration {
            if PosePlayback.travel(state: .runningIn, elapsed: elapsed).y < -2 {
                sawLift = true
                break
            }
            elapsed += 1.0 / 30.0
        }
        XCTAssertTrue(sawLift, "Run phase should include upward bounce")
    }

    func testShadowShrinksWhenDogIsAirborne() {
        var sawShrink = false
        var elapsed: TimeInterval = 0.05
        while elapsed < PosePlayback.runDuration {
            let travel = PosePlayback.travel(state: .runningIn, elapsed: elapsed)
            if travel.y < -2, travel.shadowScale < 1.05 {
                sawShrink = true
                break
            }
            elapsed += 1.0 / 30.0
        }
        XCTAssertTrue(sawShrink)
    }

    func testFullTimelineHasBoundedFrameDeltas() {
        var elapsed: TimeInterval = 0
        var previous = PosePlayback.travel(state: .runningIn, elapsed: 0)
        while elapsed < PosePlayback.runningInDuration {
            elapsed += 1.0 / 60.0
            let next = PosePlayback.travel(state: .runningIn, elapsed: elapsed)
            XCTAssertEqual(next.scaleX, 1, accuracy: 0.001)
            XCTAssertEqual(next.scaleY, 1, accuracy: 0.001)
            XCTAssertLessThan(abs(next.rotationDegrees - previous.rotationDegrees), 6.0)
            XCTAssertLessThan(abs(next.x - previous.x), 18)
            previous = next
        }
    }

    func testRunInKeepsUnityScaleWhileMoving() {
        for elapsed in stride(from: 0, through: PosePlayback.runningInDuration, by: 0.05) {
            let travel = PosePlayback.travel(state: .runningIn, elapsed: elapsed)
            XCTAssertEqual(travel.scaleX, 1, accuracy: 0.001)
            XCTAssertEqual(travel.scaleY, 1, accuracy: 0.001)
        }
    }

    // MARK: - Presentation policy

    func testFlipbookOnlyWhileFacingRightWithFrames() {
        XCTAssertTrue(RunInPresentation.showsFlipbook(
            motion: .runningIn,
            facingScaleX: -1,
            hasRunFrames: true
        ))
        XCTAssertFalse(RunInPresentation.showsFlipbook(
            motion: .runningIn,
            facingScaleX: 1,
            hasRunFrames: true
        ))
        XCTAssertFalse(RunInPresentation.showsFlipbook(
            motion: .runningIn,
            facingScaleX: -1,
            hasRunFrames: false
        ))
        XCTAssertFalse(RunInPresentation.showsFlipbook(
            motion: .idle,
            facingScaleX: -1,
            hasRunFrames: true
        ))
    }

    func testFlipbookDisabledDuringBrakeAndSettle() {
        for elapsed in stride(
            from: PosePlayback.runDuration,
            through: PosePlayback.runningInDuration,
            by: 0.05
        ) {
            let travel = PosePlayback.travel(state: .runningIn, elapsed: elapsed)
            XCTAssertFalse(RunInPresentation.showsFlipbook(
                motion: .runningIn,
                facingScaleX: travel.facingScaleX,
                hasRunFrames: true
            ))
        }
    }

    // MARK: - Rig motion

    func testRigStaysInSitStateDuringRunIn() {
        for elapsed in sampleTimes() {
            XCTAssertEqual(
                CompanionRigMotion.rigState(from: .runningIn, elapsed: elapsed),
                .sitting
            )
        }
    }

    func testFlipbookGaitBouncesWithoutCrabWalk() {
        let stepA = CompanionRigMotion.transform(
            motion: .runningIn,
            elapsed: 0.25,
            usesRunFlipbook: true
        )
        let stepB = CompanionRigMotion.transform(
            motion: .runningIn,
            elapsed: 0.25 + Double.pi / 11.0,
            usesRunFlipbook: true
        )
        XCTAssertEqual(stepA.frontLegX, 0, accuracy: 0.01)
        XCTAssertEqual(stepA.backLegX, 0, accuracy: 0.01)
        XCTAssertGreaterThan(stepA.bodyY, 0.4)
        XCTAssertGreaterThan(abs(stepA.bodyY - stepB.bodyY), 0.08)
    }

    func testCutoutGaitAlternatesLegsWhileFacingFront() {
        let stepA = CompanionRigMotion.transform(
            motion: .runningIn,
            elapsed: PosePlayback.runDuration * 0.4,
            usesRunFlipbook: false
        )
        let stepB = CompanionRigMotion.transform(
            motion: .runningIn,
            elapsed: PosePlayback.runDuration * 0.4 + Double.pi / 11.0,
            usesRunFlipbook: false
        )
        XCTAssertLessThan(stepA.headRotation, -0.08)
        XCTAssertGreaterThan(abs(stepA.frontLegY), 1.5)
        XCTAssertLessThan(stepA.frontLegY * stepB.frontLegY, 0)
    }

    func testRigBlendsIntoSittingBreatheAtEnd() {
        let sitting = CompanionRigMotion.transform(
            state: .sitting,
            time: PosePlayback.runningInDuration
        )
        let settled = CompanionRigMotion.transform(
            motion: .runningIn,
            elapsed: PosePlayback.runningInDuration
        )
        XCTAssertEqual(settled.lean, sitting.lean, accuracy: 0.03)
        XCTAssertEqual(settled.headY, sitting.headY, accuracy: 0.25)
        XCTAssertEqual(settled.bodyScaleX, sitting.bodyScaleX, accuracy: 0.03)
    }

    // MARK: - Owner dog frames

    func testSynthesizedRunFramesFromSitCutout() throws {
        let sitData = try XCTUnwrap(Self.makeSitPNGData())
        let frames = PoseFrameSynthesizer.runCycle(from: sitData)
        XCTAssertGreaterThanOrEqual(frames.count, 4)
        XCTAssertFalse(PoseFrameSynthesizer.looksLikeSamePose(sitData, frames[0]))
        XCTAssertFalse(PoseFrameSynthesizer.looksLikeSamePose(frames[0], frames[2]))

        let sitImage = try XCTUnwrap(UIImage(data: sitData))
        let frameImage = try XCTUnwrap(UIImage(data: frames[0]))
        let scale = PoseFrameSynthesizer.contentHeightScale(sitImage: sitImage, frameImage: frameImage)
        XCTAssertGreaterThan(scale, 0.85)
        XCTAssertLessThan(scale, 1.15)
    }

    func testRunFrameImagesPrefersStoredFrames() throws {
        let sit = try XCTUnwrap(Self.makeSitPNGData())
        let runA = try XCTUnwrap(Self.makeSitPNGData())
        let runB = try XCTUnwrap(Self.makeSitPNGData())
        let set = PoseCutoutSet(sit: sit, runA: runA, runB: runB, land: nil)
        XCTAssertTrue(set.canFlipbook)
        XCTAssertEqual(set.runFrameImages().count, 2)
    }

    func testRunFrameImagesSynthesizesWhenOnlySitExists() throws {
        let sit = try XCTUnwrap(Self.makeSitPNGData())
        let set = PoseCutoutSet(sit: sit, runA: nil, runB: nil, land: nil)
        let frames = set.runFrameImages()
        XCTAssertGreaterThanOrEqual(frames.count, 4)
    }

    // MARK: - Away vs run-in

    func testAwayStartsWhereRunInBegins() {
        let away = PosePlayback.travel(state: .away, elapsed: 0)
        let runStart = PosePlayback.travel(state: .runningIn, elapsed: 0)
        XCTAssertLessThan(away.x, -120)
        XCTAssertLessThan(runStart.x, -120)
        XCTAssertEqual(away.x, -PosePlayback.runDistance, accuracy: 0.5)
        XCTAssertEqual(away.opacity, 0, accuracy: 0.01)
        XCTAssertLessThan(away.facingScaleX, 0)
        XCTAssertLessThan(runStart.facingScaleX, 0)
    }

    // MARK: - Helpers

    private func sampleTimes() -> [TimeInterval] {
        var times: [TimeInterval] = [0, 0.05, PosePlayback.runDuration * 0.5]
        times.append(PosePlayback.runDuration)
        times.append(PosePlayback.runDuration + PosePlayback.brakeDuration * 0.5)
        times.append(PosePlayback.runningInDuration)
        return times
    }

    private static func makeSitPNGData() -> Data? {
        let size = CGSize(width: 48, height: 72)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            UIColor(red: 0.82, green: 0.55, blue: 0.32, alpha: 1).setFill()
            UIBezierPath(roundedRect: CGRect(x: 12, y: 6, width: 24, height: 60), cornerRadius: 10).fill()
        }
        return image.pngData()
    }
}
