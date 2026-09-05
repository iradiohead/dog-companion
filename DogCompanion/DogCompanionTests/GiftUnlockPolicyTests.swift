import XCTest
@testable import DogCompanion

final class GiftUnlockPolicyTests: XCTestCase {
    func testFirstSessionUnlocksStudyScene() {
        let companion = Companion(
            name: "Test",
            comicPortraitData: nil,
            cutoutData: nil,
            styleTemplate: .default
        )

        let unlocked = GiftUnlockPolicy.applyRewards(for: 1, to: companion)

        XCTAssertTrue(unlocked.contains("cozy_study"))
        XCTAssertTrue(companion.isUnlocked("cozy_study"))
    }

    func testSecondSessionUnlocksBlueCushion() {
        let companion = Companion(
            name: "Test",
            comicPortraitData: nil,
            cutoutData: nil,
            styleTemplate: .default
        )

        let unlocked = GiftUnlockPolicy.applyRewards(for: 2, to: companion)

        XCTAssertTrue(unlocked.contains("cushion_blue"))
        XCTAssertTrue(companion.isUnlocked("cushion_blue"))
    }

    func testGiftTitleForSceneUnlock() {
        let title = GiftUnlockPolicy.giftTitle(for: 1, unlockedItems: ["cozy_study"])
        XCTAssertEqual(title, "解锁场景：安静书房")
    }

    func testGiftTitleForSnackWhenNothingUnlocked() {
        let title = GiftUnlockPolicy.giftTitle(for: 5, unlockedItems: [])
        XCTAssertEqual(title, "小零食")
    }
}
