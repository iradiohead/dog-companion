import XCTest
@testable import DogCompanion

final class VitalStatsCalculatorTests: XCTestCase {
    func testClamp() {
        XCTAssertEqual(VitalStatsCalculator.clamp(150), 100)
        XCTAssertEqual(VitalStatsCalculator.clamp(-10), 0)
        XCTAssertEqual(VitalStatsCalculator.clamp(50), 50)
    }

    func testFeedIncreasesHunger() {
        XCTAssertEqual(VitalStatsCalculator.feed(hunger: 50), 80)
        XCTAssertEqual(VitalStatsCalculator.feed(hunger: 90), 100)
    }

    func testPlayIncreasesMood() {
        XCTAssertEqual(VitalStatsCalculator.play(mood: 40), 70)
        XCTAssertEqual(VitalStatsCalculator.play(mood: 95), 100)
    }

    func testWalkAdjustsBothStats() {
        let result = VitalStatsCalculator.walk(hunger: 50, mood: 50)
        XCTAssertEqual(result.hunger, 40)
        XCTAssertEqual(result.mood, 70)
    }

    func testDecayAfterFourHoursReducesHunger() {
        let lastUpdated = Date(timeIntervalSince1970: 0)
        let now = Date(timeIntervalSince1970: VitalStatsCalculator.hungerDecayInterval)
        let result = VitalStatsCalculator.applyDecay(hunger: 80, mood: 80, lastUpdated: lastUpdated, now: now)
        XCTAssertEqual(result.hunger, 60)
        XCTAssertEqual(result.mood, 80)
    }

    func testDecayAfterSixHoursReducesMood() {
        let lastUpdated = Date(timeIntervalSince1970: 0)
        let now = Date(timeIntervalSince1970: VitalStatsCalculator.moodDecayInterval)
        let result = VitalStatsCalculator.applyDecay(hunger: 80, mood: 80, lastUpdated: lastUpdated, now: now)
        XCTAssertEqual(result.hunger, 80)
        XCTAssertEqual(result.mood, 60)
    }

    func testDecayAppliesMultipleTicks() {
        let lastUpdated = Date(timeIntervalSince1970: 0)
        let now = Date(timeIntervalSince1970: VitalStatsCalculator.hungerDecayInterval * 3)
        let result = VitalStatsCalculator.applyDecay(hunger: 100, mood: 100, lastUpdated: lastUpdated, now: now)
        XCTAssertEqual(result.hunger, 40)
    }

    func testExpressionTierMapping() {
        XCTAssertEqual(ExpressionTier(value: 100), .excellent)
        XCTAssertEqual(ExpressionTier(value: 75), .good)
        XCTAssertEqual(ExpressionTier(value: 50), .okay)
        XCTAssertEqual(ExpressionTier(value: 30), .low)
        XCTAssertEqual(ExpressionTier(value: 10), .critical)
    }
}

final class RegenerationPolicyTests: XCTestCase {
    func testRemainingRegenerations() {
        XCTAssertEqual(RegenerationPolicy.remaining(usedCount: 0), 3)
        XCTAssertEqual(RegenerationPolicy.remaining(usedCount: 2), 1)
        XCTAssertEqual(RegenerationPolicy.remaining(usedCount: 3), 0)
    }

    func testCanRegenerate() {
        XCTAssertTrue(RegenerationPolicy.canRegenerate(usedCount: 0))
        XCTAssertTrue(RegenerationPolicy.canRegenerate(usedCount: 2))
        XCTAssertFalse(RegenerationPolicy.canRegenerate(usedCount: 3))
    }
}
