import XCTest
import UIKit
@testable import DogCompanion

final class PosePlaybackTests: XCTestCase {
    func testRunningInAnticipatesThenGallopsThenLandsAndSits() {
        XCTAssertEqual(PosePlayback.pose(state: .runningIn, elapsed: 0), .sit)
        XCTAssertEqual(
            PosePlayback.pose(state: .runningIn, elapsed: PosePlayback.anticipateDuration + 0.01),
            .runA
        )
        XCTAssertEqual(
            PosePlayback.pose(state: .runningIn, elapsed: PosePlayback.anticipateDuration + 0.12),
            .runB
        )
        XCTAssertEqual(
            PosePlayback.pose(state: .runningIn, elapsed: PosePlayback.anticipateDuration + 0.23),
            .runC
        )
        XCTAssertEqual(
            PosePlayback.pose(state: .runningIn, elapsed: PosePlayback.anticipateDuration + 0.34),
            .runD
        )
        XCTAssertEqual(
            PosePlayback.pose(state: .runningIn, elapsed: PosePlayback.anticipateDuration + PosePlayback.runDuration + 0.05),
            .land
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

    func testAnticipateCrouchesBeforeTheRun() {
        let crouch = PosePlayback.travel(state: .runningIn, elapsed: 0.1)
        XCTAssertLessThan(crouch.scaleY, 0.92)
        XCTAssertGreaterThan(crouch.scaleX, 1.08)
        XCTAssertLessThan(crouch.x, -100)
        XCTAssertGreaterThan(crouch.opacity, 0.5)
    }

    func testRunningInTravelsFromLeftToTheMat() {
        let start = PosePlayback.travel(state: .runningIn, elapsed: 0)
        let end = PosePlayback.travel(
            state: .runningIn,
            elapsed: PosePlayback.anticipateDuration + PosePlayback.runDuration
        )
        XCTAssertLessThan(start.x, end.x)
        XCTAssertEqual(end.x, 0, accuracy: 1.5)
    }

    func testRunHasAirborneHop() {
        var lowest: CGFloat = 0
        var elapsed = PosePlayback.anticipateDuration
        let end = elapsed + PosePlayback.runDuration
        while elapsed < end {
            lowest = min(lowest, PosePlayback.travel(state: .runningIn, elapsed: elapsed).y)
            elapsed += 0.02
        }
        XCTAssertLessThan(lowest, -8)
    }

    func testLandSquashesThenSettleCrossfadesToSit() {
        let landElapsed = PosePlayback.anticipateDuration + PosePlayback.runDuration + 0.04
        let land = PosePlayback.snapshot(state: .runningIn, elapsed: landElapsed)
        XCTAssertEqual(land.pose, .land)
        XCTAssertLessThan(land.travel.scaleY, 0.88)

        let settled = PosePlayback.snapshot(state: .runningIn, elapsed: PosePlayback.runningInDuration)
        XCTAssertEqual(settled.pose, .sit)
        XCTAssertEqual(settled.travel.x, 0, accuracy: 0.5)

        let settling = PosePlayback.snapshot(
            state: .runningIn,
            elapsed: PosePlayback.anticipateDuration + PosePlayback.runDuration + PosePlayback.landDuration + 0.12
        )
        XCTAssertEqual(settling.pose, .land)
        XCTAssertEqual(settling.nextPose, .sit)
        XCTAssertGreaterThan(settling.crossfade, 0.15)
    }

    func testAwayStartsOffscreenLeft() {
        let away = PosePlayback.travel(state: .away, elapsed: 0)
        XCTAssertEqual(away.opacity, 0, accuracy: 0.01)
        XCTAssertLessThan(away.x, -100)
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

    func testSynthesizedFallbacksFillMissingRunFrames() throws {
        let sit = try makeOpaqueDogPNG()
        let filled = PoseCutoutSet(sit: sit, runA: nil, runB: nil, land: nil).withSynthesizedFallbacks()
        XCTAssertNotNil(filled.runA)
        XCTAssertNotNil(filled.runB)
        XCTAssertNotNil(filled.runC)
        XCTAssertNotNil(filled.runD)
        XCTAssertNotNil(filled.land)
        XCTAssertNotEqual(filled.runA, sit)
        XCTAssertNotEqual(filled.runA, filled.runC)
    }

    func testRunCycleMovesOppositeLegs() throws {
        let sit = try makeOpaqueDogPNG()
        let cycle = PoseFrameSynthesizer.runCycle(from: sit)
        XCTAssertEqual(cycle.count, 4)
        XCTAssertFalse(PoseFrameSynthesizer.looksLikeSamePose(cycle[0], cycle[2]))
        XCTAssertTrue(PoseFrameSynthesizer.looksLikeSamePose(sit, sit))
    }

    func testRunningInDurationCoversTheFullBeat() {
        XCTAssertEqual(
            PosePlayback.runningInDuration,
            PosePlayback.anticipateDuration
                + PosePlayback.runDuration
                + PosePlayback.landDuration
                + PosePlayback.settleDuration,
            accuracy: 0.001
        )
        XCTAssertGreaterThan(PosePlayback.runningInDuration, 2)
    }

    func testIdleBreathChangesScaleOverTime() {
        let a = PosePlayback.travel(state: .idle, elapsed: 0)
        let b = PosePlayback.travel(state: .idle, elapsed: 0.8)
        XCTAssertGreaterThan(abs(a.scaleY - b.scaleY), 0.001)
    }

    private func makeOpaqueDogPNG() throws -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 64, height: 64))
        let image = renderer.image { _ in
            UIColor.clear.setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: 64, height: 64))
            UIColor.brown.setFill()
            UIRectFill(CGRect(x: 18, y: 8, width: 28, height: 26))
            UIRectFill(CGRect(x: 14, y: 32, width: 14, height: 24))
            UIRectFill(CGRect(x: 36, y: 32, width: 14, height: 24))
        }
        guard let data = image.pngData() else {
            struct PNGError: Error {}
            throw PNGError()
        }
        return data
    }
}
