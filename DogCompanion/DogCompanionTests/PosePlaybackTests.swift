import XCTest
import UIKit
@testable import DogCompanion

final class PosePlaybackTests: XCTestCase {
    func testRunningInAlternatesRunFramesThenLandsAndSits() {
        XCTAssertEqual(PosePlayback.pose(state: .runningIn, elapsed: 0), .runA)
        XCTAssertEqual(PosePlayback.pose(state: .runningIn, elapsed: 0.12), .runB)
        XCTAssertEqual(PosePlayback.pose(state: .runningIn, elapsed: PosePlayback.runDuration + 0.05), .land)
        XCTAssertEqual(PosePlayback.pose(state: .runningIn, elapsed: PosePlayback.runningInDuration + 0.05), .sit)
    }

    func testIdleAndAwayUseSitFrame() {
        XCTAssertEqual(PosePlayback.pose(state: .idle, elapsed: 1), .sit)
        XCTAssertEqual(PosePlayback.pose(state: .away, elapsed: 0), .sit)
    }

    func testRunningInTravelsFromLeftToTheMat() {
        let start = PosePlayback.travel(state: .runningIn, elapsed: 0)
        let end = PosePlayback.travel(state: .runningIn, elapsed: PosePlayback.runDuration)
        XCTAssertLessThan(start.x, end.x)
        XCTAssertEqual(start.x, -PosePlayback.runDistance, accuracy: 0.5)
        XCTAssertEqual(end.x, 0, accuracy: 0.5)
        XCTAssertEqual(start.scale, 1, accuracy: 0.01)
        XCTAssertEqual(end.scale, 1, accuracy: 0.01)
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
        XCTAssertNotNil(filled.land)
        XCTAssertNotEqual(filled.runA, sit)
        XCTAssertNotEqual(filled.runB, filled.runA)
    }

    func testRunningInDurationCoversLandFrame() {
        XCTAssertEqual(
            PosePlayback.runningInDuration,
            PosePlayback.runDuration + PosePlayback.landDuration,
            accuracy: 0.001
        )
        XCTAssertGreaterThan(PosePlayback.runningInDuration, 2)
    }

    private func makeOpaqueDogPNG() throws -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 32))
        let image = renderer.image { _ in
            UIColor.clear.setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: 32, height: 32))
            UIColor.brown.setFill()
            UIRectFill(CGRect(x: 8, y: 10, width: 16, height: 18))
        }
        guard let data = image.pngData() else {
            struct PNGError: Error {}
            throw PNGError()
        }
        return data
    }
}
