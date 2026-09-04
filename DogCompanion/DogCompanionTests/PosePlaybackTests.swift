import XCTest
@testable import DogCompanion

final class PosePlaybackTests: XCTestCase {
    func testRunningInAlternatesRunFramesThenLandsAndSits() {
        XCTAssertEqual(PosePlayback.pose(state: .runningIn, elapsed: 0), .runA)
        XCTAssertEqual(PosePlayback.pose(state: .runningIn, elapsed: 0.13), .runB)
        XCTAssertEqual(PosePlayback.pose(state: .runningIn, elapsed: 1.3), .land)
        XCTAssertEqual(PosePlayback.pose(state: .runningIn, elapsed: 1.7), .sit)
    }

    func testIdleAndAwayUseSitFrame() {
        XCTAssertEqual(PosePlayback.pose(state: .idle, elapsed: 1), .sit)
        XCTAssertEqual(PosePlayback.pose(state: .away, elapsed: 0), .sit)
    }

    func testRunningInTravelsFromFarToNear() {
        let start = PosePlayback.travel(state: .runningIn, elapsed: 0)
        let end = PosePlayback.travel(state: .runningIn, elapsed: PosePlayback.runDuration)
        XCTAssertGreaterThan(start.x, end.x)
        XCTAssertLessThan(start.scale, end.scale)
        XCTAssertEqual(end.x, 0, accuracy: 0.5)
    }

    func testPosePromptsDescribeDifferentActions() {
        XCTAssertTrue(CompanionPose.sit.promptInstruction.contains("坐"))
        XCTAssertTrue(CompanionPose.runA.promptInstruction.contains("奔跑"))
        XCTAssertTrue(CompanionPose.runB.promptInstruction.contains("奔跑"))
        XCTAssertTrue(CompanionPose.land.promptInstruction.contains("蹲"))
    }

    func testFlipbookFallsBackToSitWhenRunFramesMissing() {
        let set = PoseCutoutSet(sit: Data([1]), runA: nil, runB: nil, land: nil)
        XCTAssertFalse(set.canFlipbook)
        XCTAssertEqual(set.data(for: .runA), Data([1]))
        XCTAssertEqual(set.data(for: .land), Data([1]))
    }
}
