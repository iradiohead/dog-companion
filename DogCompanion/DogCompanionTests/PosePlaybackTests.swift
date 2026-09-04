import XCTest
import UIKit
@testable import DogCompanion

final class PosePlaybackTests: XCTestCase {
    func testJumpOnUsesSitPoseTheWholeWay() {
        XCTAssertEqual(PosePlayback.pose(state: .runningIn, elapsed: 0), .sit)
        XCTAssertEqual(
            PosePlayback.pose(state: .runningIn, elapsed: PosePlayback.crouchDuration + 0.3),
            .sit
        )
        XCTAssertEqual(
            PosePlayback.pose(state: .runningIn, elapsed: PosePlayback.crouchDuration + PosePlayback.jumpDuration + 0.05),
            .sit
        )
        XCTAssertEqual(
            PosePlayback.pose(state: .runningIn, elapsed: PosePlayback.runningInDuration),
            .sit
        )
    }

    func testIdleAndAwayUseSitFrame() {
        XCTAssertEqual(PosePlayback.pose(state: .idle, elapsed: 1), .sit)
        XCTAssertEqual(PosePlayback.pose(state: .away, elapsed: 0), .sit)
    }

    func testCrouchBeforeJump() {
        let crouch = PosePlayback.travel(state: .runningIn, elapsed: PosePlayback.crouchStart + 0.15)
        XCTAssertLessThan(crouch.scaleY, 0.98)
        XCTAssertGreaterThan(crouch.scaleX, 1.02)
        XCTAssertLessThan(crouch.x, -10)
        XCTAssertGreaterThan(crouch.opacity, 0.5)
    }

    func testRunInStartsSmallAndFarLeft() {
        let start = PosePlayback.travel(state: .runningIn, elapsed: 0.05)
        XCTAssertLessThan(start.x, -150)
        XCTAssertLessThan(start.scaleY, 0.55)
        XCTAssertGreaterThan(start.opacity, 0.2)
    }

    func testRunInGrowsWhileMovingRight() {
        let early = PosePlayback.travel(state: .runningIn, elapsed: 0.2)
        let late = PosePlayback.travel(state: .runningIn, elapsed: PosePlayback.runDuration - 0.05)
        XCTAssertGreaterThan(late.x, early.x)
        XCTAssertGreaterThan(late.scaleY, early.scaleY)
        XCTAssertGreaterThan(late.scaleY, 0.85)
    }

    func testJumpTravelsFromLeftToTheMat() {
        let start = PosePlayback.travel(state: .runningIn, elapsed: 0)
        let end = PosePlayback.travel(state: .runningIn, elapsed: PosePlayback.landStart)
        XCTAssertLessThan(start.x, end.x)
        XCTAssertEqual(end.x, 0, accuracy: 2)
    }

    func testJumpHasOneArc() {
        let mid = PosePlayback.travel(
            state: .runningIn,
            elapsed: PosePlayback.jumpStart + PosePlayback.jumpDuration * 0.5
        )
        XCTAssertLessThan(mid.y, -20)

        var lowest: CGFloat = 0
        var elapsed = PosePlayback.jumpStart
        let end = elapsed + PosePlayback.jumpDuration
        while elapsed < end {
            lowest = min(lowest, PosePlayback.travel(state: .runningIn, elapsed: elapsed).y)
            elapsed += 0.03
        }
        XCTAssertLessThan(lowest, -20)
        XCTAssertGreaterThan(lowest, -50)
    }

    func testLandSquashesGentlyThenSits() {
        let land = PosePlayback.travel(
            state: .runningIn,
            elapsed: PosePlayback.landStart + 0.03
        )
        XCTAssertLessThan(land.scaleY, 0.97)
        XCTAssertEqual(land.x, 0, accuracy: 0.5)

        let settled = PosePlayback.snapshot(state: .runningIn, elapsed: PosePlayback.runningInDuration)
        XCTAssertEqual(settled.pose, .sit)
        XCTAssertEqual(settled.travel.x, 0, accuracy: 0.5)
        XCTAssertEqual(settled.travel.y, 0, accuracy: 0.5)
    }

    func testAwayStartsOffscreenLeft() {
        let away = PosePlayback.travel(state: .away, elapsed: 0)
        XCTAssertEqual(away.opacity, 0, accuracy: 0.01)
        XCTAssertLessThan(away.x, -80)
    }

    func testPosePromptsDescribeDifferentActions() {
        XCTAssertTrue(CompanionPose.sit.promptInstruction.contains("坐"))
        XCTAssertTrue(CompanionPose.runA.promptInstruction.contains("奔跑"))
        XCTAssertTrue(CompanionPose.runB.promptInstruction.contains("奔跑"))
        XCTAssertTrue(CompanionPose.runA.promptInstruction.contains("不能坐"))
        XCTAssertTrue(CompanionPose.land.promptInstruction.contains("不能已经坐稳"))
    }

    func testActionPromptForbidsCopyingSitPose() {
        let prompt = StyleTemplate.anime.prompt(for: .runA)
        XCTAssertTrue(prompt.contains("奔跑"))
        XCTAssertTrue(prompt.contains("不要复制参考图里的坐姿"))
        XCTAssertTrue(StyleTemplate.anime.negativePrompt(for: .runA).contains("sitting"))
    }

    func testFlipbookFallsBackToSitWhenRunFramesMissing() {
        let set = PoseCutoutSet(sit: Data([1]), runA: nil, runB: nil, land: nil)
        XCTAssertFalse(set.canFlipbook)
        XCTAssertEqual(set.data(for: .runA), Data([1]))
        XCTAssertEqual(set.data(for: .land), Data([1]))
    }

    func testJumpScaleChangesContinuously() {
        var elapsed: TimeInterval = 0
        var previous = PosePlayback.travel(state: .runningIn, elapsed: 0)
        while elapsed < PosePlayback.runningInDuration {
            elapsed += 1.0 / 60.0
            let next = PosePlayback.travel(state: .runningIn, elapsed: elapsed)
            XCTAssertLessThan(abs(next.scaleY - previous.scaleY), 0.08)
            XCTAssertLessThan(abs(next.rotationDegrees - previous.rotationDegrees), 4.0)
            previous = next
        }
    }

    func testJumpDurationIsASingleBeat() {
        XCTAssertEqual(
            PosePlayback.runningInDuration,
            PosePlayback.runDuration
                + PosePlayback.crouchDuration
                + PosePlayback.jumpDuration
                + PosePlayback.landDuration
                + PosePlayback.settleDuration,
            accuracy: 0.001
        )
        XCTAssertGreaterThan(PosePlayback.runningInDuration, 2.8)
        XCTAssertLessThan(PosePlayback.runningInDuration, 3.8)
    }

    func testIdleTravelStaysStillWhileMeshWarps() {
        let a = PosePlayback.travel(state: .idle, elapsed: 0)
        let b = PosePlayback.travel(state: .idle, elapsed: 1.0)
        XCTAssertEqual(a.scaleY, 1, accuracy: 0.0001)
        XCTAssertEqual(b.scaleY, 1, accuracy: 0.0001)
        XCTAssertEqual(a.x, 0, accuracy: 0.0001)
    }
}
