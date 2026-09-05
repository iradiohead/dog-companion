import XCTest
@testable import DogCompanion

@MainActor
final class HomeViewModelTests: XCTestCase {
    private func makeCompanion() -> Companion {
        Companion(
            name: "TestDog",
            comicPortraitData: nil,
            cutoutData: nil,
            styleTemplate: .default
        )
    }

    func testInitialStateIsIdleAndHidden() {
        let viewModel = HomeViewModel()
        XCTAssertEqual(viewModel.phase, .idle)
        XCTAssertEqual(viewModel.motionState, .idle)
        XCTAssertFalse(viewModel.isFocusActive)
    }

    func testStartFocusHidesThenRunsIn() async {
        let viewModel = HomeViewModel()
        viewModel.startFocus(with: makeCompanion())

        XCTAssertEqual(viewModel.phase, .running)
        XCTAssertEqual(viewModel.motionState, .away)
        XCTAssertTrue(viewModel.isFocusActive)

        try? await Task.sleep(nanoseconds: 20_000_000)
        XCTAssertEqual(viewModel.motionState, .runningIn)
    }

    func testCancelFocusHidesCompanion() async {
        let viewModel = HomeViewModel()
        viewModel.startFocus(with: makeCompanion())
        try? await Task.sleep(nanoseconds: 20_000_000)
        viewModel.cancelFocus()

        XCTAssertEqual(viewModel.phase, .idle)
        XCTAssertEqual(viewModel.motionState, .away)
        XCTAssertFalse(viewModel.isFocusActive)
    }

    func testReactDuringRunInIsAllowed() async {
        let viewModel = HomeViewModel()
        viewModel.startFocus(with: makeCompanion())
        try? await Task.sleep(nanoseconds: 20_000_000)
        XCTAssertEqual(viewModel.motionState, .runningIn)

        viewModel.reactToTap()
        XCTAssertEqual(viewModel.motionState, .reacting)

        try? await Task.sleep(nanoseconds: 950_000_000)
        XCTAssertEqual(viewModel.motionState, .idle)
    }

    func testReactIgnoredWhileCelebrating() {
        let viewModel = HomeViewModel()
        let companion = makeCompanion()
        viewModel.startFocus(with: companion)
        viewModel.completeFocus(for: companion)

        XCTAssertEqual(viewModel.motionState, .celebrating)
        viewModel.reactToTap()
        XCTAssertEqual(viewModel.motionState, .celebrating)
    }

    func testRunInCompletesToIdleAfterAnimation() async {
        let viewModel = HomeViewModel()
        viewModel.startFocus(with: makeCompanion())
        try? await Task.sleep(nanoseconds: 20_000_000)
        XCTAssertEqual(viewModel.motionState, .runningIn)

        let wait = PosePlayback.runningInDuration + 0.12
        try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))

        XCTAssertEqual(viewModel.motionState, .idle)
        XCTAssertEqual(viewModel.phase, .running, "Timer should still be running after run-in")
    }

    func testDismissGiftReturnsToAway() {
        let viewModel = HomeViewModel()
        let companion = makeCompanion()
        viewModel.startFocus(with: companion)
        viewModel.completeFocus(for: companion)
        XCTAssertTrue(viewModel.showGiftReveal)

        viewModel.dismissGift()
        XCTAssertFalse(viewModel.showGiftReveal)
        XCTAssertEqual(viewModel.phase, .idle)
        XCTAssertEqual(viewModel.motionState, .away)
    }

    func testFormattedRemainingTimeShowsMinutesAndSeconds() {
        let viewModel = HomeViewModel()
        viewModel.startFocus(with: makeCompanion())
        XCTAssertFalse(viewModel.formattedRemainingTime.isEmpty)
        XCTAssertTrue(viewModel.formattedRemainingTime.contains(":"))
    }
}

final class SceneRoomLayoutTests: XCTestCase {
    func testZeroHeightDoesNotProduceNegativeFrames() {
        let split = SceneRoomLayout.wallAndFloorHeights(in: 0)
        XCTAssertEqual(split.wall, 0)
        XCTAssertEqual(split.floor, 0)
    }

    func testShortHeightKeepsFloorWithinBounds() {
        let split = SceneRoomLayout.wallAndFloorHeights(in: 200)
        XCTAssertGreaterThanOrEqual(split.wall, 0)
        XCTAssertGreaterThanOrEqual(split.floor, 0)
        XCTAssertEqual(split.wall + split.floor, 200)
        XCTAssertEqual(split.floor, 200)
    }

    func testTallHeightKeepsWallNonNegative() {
        let split = SceneRoomLayout.wallAndFloorHeights(in: 580)
        XCTAssertGreaterThan(split.wall, 0)
        XCTAssertGreaterThan(split.floor, 0)
        XCTAssertEqual(split.wall + split.floor, 580, accuracy: 0.001)
        XCTAssertLessThan(split.floor, 580)
    }
}
