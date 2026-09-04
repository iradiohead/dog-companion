import XCTest
import UIKit
@testable import DogCompanion

final class PosePlaybackTests: XCTestCase {
    func testHopOnUsesSitPoseTheWholeWay() {
        XCTAssertEqual(PosePlayback.pose(state: .runningIn, elapsed: 0.05), .sit)
        XCTAssertEqual(
            PosePlayback.pose(state: .runningIn, elapsed: PosePlayback.jumpStart + 0.2),
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
        let crouch = PosePlayback.travel(
            state: .runningIn,
            elapsed: PosePlayback.crouchDuration * 0.9
        )
        XCTAssertLessThan(crouch.scaleY, 0.96)
        XCTAssertGreaterThan(crouch.scaleX, 1.02)
        XCTAssertEqual(crouch.x, 0, accuracy: 1)
        XCTAssertGreaterThan(crouch.y, 50)
        XCTAssertGreaterThan(crouch.opacity, 0.5)
    }

    func testHopStartsInFrontOfTheMat() {
        let start = PosePlayback.travel(state: .runningIn, elapsed: 0.05)
        XCTAssertEqual(start.x, 0, accuracy: 1)
        XCTAssertGreaterThan(start.y, 50)
        XCTAssertLessThan(start.y, 80)
        XCTAssertGreaterThan(start.scaleY, 0.95)
        XCTAssertGreaterThan(start.opacity, 0.2)
    }

    func testJumpClimbsFromFrontOntoTheMat() {
        let start = PosePlayback.travel(state: .runningIn, elapsed: 0)
        let end = PosePlayback.travel(state: .runningIn, elapsed: PosePlayback.landStart)
        XCTAssertGreaterThan(start.y, end.y)
        XCTAssertEqual(end.x, 0, accuracy: 2)
        XCTAssertEqual(end.y, 0, accuracy: 2)
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
        XCTAssertLessThan(land.scaleY, 0.96)
        XCTAssertEqual(land.x, 0, accuracy: 0.5)

        let settled = PosePlayback.snapshot(state: .runningIn, elapsed: PosePlayback.runningInDuration)
        XCTAssertEqual(settled.pose, .sit)
        XCTAssertEqual(settled.travel.x, 0, accuracy: 0.5)
        XCTAssertEqual(settled.travel.y, 0, accuracy: 0.5)
    }

    func testAwayHidesInFrontOfTheMat() {
        let away = PosePlayback.travel(state: .away, elapsed: 0)
        XCTAssertEqual(away.opacity, 0, accuracy: 0.01)
        XCTAssertEqual(away.x, 0, accuracy: 0.5)
        XCTAssertEqual(away.y, PosePlayback.hopFrontY, accuracy: 0.5)
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

    func testHopOnDurationIsAboutOneSecond() {
        XCTAssertEqual(
            PosePlayback.runningInDuration,
            PosePlayback.crouchDuration
                + PosePlayback.jumpDuration
                + PosePlayback.landDuration
                + PosePlayback.settleDuration,
            accuracy: 0.001
        )
        XCTAssertGreaterThan(PosePlayback.runningInDuration, 1.05)
        XCTAssertLessThan(PosePlayback.runningInDuration, 1.35)
    }

    func testIdleTravelStaysStillWhilePartsBreathe() {
        let a = PosePlayback.travel(state: .idle, elapsed: 0)
        let b = PosePlayback.travel(state: .idle, elapsed: 1.0)
        XCTAssertEqual(a.scaleY, 1, accuracy: 0.0001)
        XCTAssertEqual(b.scaleY, 1, accuracy: 0.0001)
        XCTAssertEqual(a.x, 0, accuracy: 0.0001)
    }
}
