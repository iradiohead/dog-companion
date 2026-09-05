import XCTest
import UIKit
@testable import DogCompanion

final class PosePlaybackTests: XCTestCase {
    func testRunInUsesSitArtTheWholeWay() {
        XCTAssertEqual(PosePlayback.pose(state: .runningIn, elapsed: 0.05), .sit)
        XCTAssertEqual(
            PosePlayback.pose(state: .runningIn, elapsed: PosePlayback.runDuration * 0.5),
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

    func testRunInStartsOffToTheLeft() {
        let start = PosePlayback.travel(state: .runningIn, elapsed: 0.05)
        XCTAssertLessThan(start.x, -80)
        XCTAssertEqual(start.y, 0, accuracy: 10)
        XCTAssertGreaterThan(start.opacity, 0.2)
    }

    func testRunInEndsSittingOnTheFloor() {
        let end = PosePlayback.travel(
            state: .runningIn,
            elapsed: PosePlayback.runningInDuration
        )
        XCTAssertEqual(end.x, 0, accuracy: 2)
        XCTAssertEqual(end.y, 0, accuracy: 2)
        XCTAssertEqual(end.opacity, 1, accuracy: 0.01)
        XCTAssertEqual(end.scaleX, 1, accuracy: 0.05)
        XCTAssertEqual(end.scaleY, 1, accuracy: 0.05)
        XCTAssertEqual(end.facingScaleX, 1, accuracy: 0.01)
    }

    func testRunInStartsFacingRight() {
        let start = PosePlayback.travel(state: .runningIn, elapsed: 0.05)
        XCTAssertLessThan(start.facingScaleX, 0)
    }

    func testRunInMovesRightward() {
        let start = PosePlayback.travel(state: .runningIn, elapsed: 0.05)
        let mid = PosePlayback.travel(
            state: .runningIn,
            elapsed: PosePlayback.runDuration * 0.55
        )
        let end = PosePlayback.travel(
            state: .runningIn,
            elapsed: PosePlayback.runDuration
        )
        XCTAssertGreaterThan(mid.x, start.x)
        XCTAssertGreaterThan(end.x, mid.x)
        XCTAssertEqual(end.x, 0, accuracy: 8)
    }

    func testBrakeSettlesTowardRest() {
        let brake = PosePlayback.travel(
            state: .runningIn,
            elapsed: PosePlayback.brakeStart + 0.08
        )
        XCTAssertEqual(brake.x, 0, accuracy: 2)
        XCTAssertGreaterThan(brake.scaleY, 0.96)
        XCTAssertLessThan(abs(brake.rotationDegrees), 5)
    }

    func testAwayHidesOffToTheLeft() {
        let away = PosePlayback.travel(state: .away, elapsed: 0)
        XCTAssertEqual(away.opacity, 0, accuracy: 0.01)
        XCTAssertEqual(away.x, -PosePlayback.runDistance, accuracy: 0.5)
        XCTAssertEqual(away.y, 0, accuracy: 0.5)
    }

    func testPosePromptsDescribeDifferentActions() {
        XCTAssertTrue(CompanionPose.sit.promptInstruction.contains("坐"))
        XCTAssertTrue(CompanionPose.runA.promptInstruction.contains("奔跑"))
        XCTAssertTrue(CompanionPose.runB.promptInstruction.contains("奔跑"))
        XCTAssertTrue(CompanionPose.runA.promptInstruction.contains("不能坐"))
        XCTAssertTrue(CompanionPose.land.promptInstruction.contains("不能已经坐稳"))
    }

    func testSitPromptPreservesPhotoIdentity() {
        let prompt = StyleTemplate.default.prompt(for: .sit)
        XCTAssertTrue(prompt.contains("一眼能认出"))
        XCTAssertTrue(prompt.contains("坐姿"))
        XCTAssertTrue(prompt.contains("#FFFFFF"))
        XCTAssertTrue(prompt.contains("手绘"))
        XCTAssertFalse(prompt.contains("共用"))
        XCTAssertFalse(prompt.contains("剪纸"))
        XCTAssertEqual(StyleTemplate.default.displayName, "手绘")
        XCTAssertTrue(StyleTemplate.default.shortDescription.contains("那只"))
        XCTAssertTrue(StyleTemplate.default.negativePrompt(for: .runA).contains("sitting"))
        XCTAssertEqual(StyleTemplate(rawValue: "anime"), .handDrawn)
        XCTAssertEqual(StyleTemplate(rawValue: "watercolor"), .handDrawn)
    }

    func testFlipbookFallsBackToSitWhenRunFramesMissing() {
        let set = PoseCutoutSet(sit: Data([1]), runA: nil, runB: nil, land: nil)
        XCTAssertFalse(set.canFlipbook)
        XCTAssertEqual(set.data(for: .runA), Data([1]))
        XCTAssertEqual(set.data(for: .land), Data([1]))
        XCTAssertTrue(set.runFrameImages().isEmpty)
    }

    func testRunInScaleStaysUnityThroughout() {
        var elapsed: TimeInterval = 0
        while elapsed <= PosePlayback.runningInDuration {
            let travel = PosePlayback.travel(state: .runningIn, elapsed: elapsed)
            XCTAssertEqual(travel.scaleX, 1, accuracy: 0.001, "at \(elapsed)s")
            XCTAssertEqual(travel.scaleY, 1, accuracy: 0.001, "at \(elapsed)s")
            if elapsed >= PosePlayback.runDuration {
                XCTAssertEqual(travel.opacity, 1, accuracy: 0.001, "at \(elapsed)s")
            }
            elapsed += 1.0 / 60.0
        }
    }

    func testRunInDurationIsAboutOneSecond() {
        XCTAssertEqual(
            PosePlayback.runningInDuration,
            PosePlayback.runDuration
                + PosePlayback.brakeDuration
                + PosePlayback.settleDuration,
            accuracy: 0.001
        )
        XCTAssertGreaterThan(PosePlayback.runningInDuration, 1.05)
        XCTAssertLessThan(PosePlayback.runningInDuration, 1.45)
    }

    func testIdleTravelStaysStillWhilePartsBreathe() {
        let a = PosePlayback.travel(state: .idle, elapsed: 0)
        let b = PosePlayback.travel(state: .idle, elapsed: 1.0)
        XCTAssertEqual(a.scaleY, 1, accuracy: 0.0001)
        XCTAssertEqual(b.scaleY, 1, accuracy: 0.0001)
        XCTAssertEqual(a.x, 0, accuracy: 0.0001)
    }
}
