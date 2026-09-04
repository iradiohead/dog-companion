import XCTest
import SwiftUI
@testable import DogCompanion

/// Smoke tests for UI theme symbols referenced across hand-drawn views.
/// Catches missing HandDrawnPalette members before Xcode build.
final class HandDrawnPaletteTests: XCTestCase {
    func testPaletteColorsExist() {
        _ = HandDrawnPalette.ink
        _ = HandDrawnPalette.inkLight
        _ = HandDrawnPalette.paper
        _ = HandDrawnPalette.cream
        _ = HandDrawnPalette.warmGlow
        _ = HandDrawnPalette.paperBase
        _ = HandDrawnPalette.timerGreen
        _ = HandDrawnPalette.timerGreenStroke
        _ = HandDrawnPalette.startBlue
        _ = HandDrawnPalette.chairGreen
        _ = HandDrawnPalette.rugPurple
        _ = HandDrawnPalette.wood
    }

    func testHomeTabCasesExist() {
        let tabs: [HomeTab] = [.stats, .timeline, .decor]
        XCTAssertEqual(tabs.count, 3)
    }

    func testHandDrawnTextureHelpersExist() {
        _ = HandDrawnFont.brush(18)
        _ = HandDrawnFont.marker(32)
        _ = HandDrawnTimerText(time: "25:00")
        _ = HandDrawnTexture.hash(3, 5)
        _ = HandDrawnPalette.ink.lighter(by: 0.1)
        _ = HandDrawnPalette.wood.darker(by: 0.1)
    }

    func testCompanionMotionStatesExist() {
        let states: [CompanionMotionState] = [.away, .runningIn, .idle, .reacting, .celebrating]
        XCTAssertEqual(states.count, 5)
        XCTAssertNotEqual(CompanionMotionState.away, .runningIn)
        XCTAssertEqual(CompanionRigMotion.rigState(from: .idle), .sitting)
        XCTAssertEqual(CompanionRigMotion.rigState(from: .runningIn, elapsed: 0), .running)
        _ = PrototypeRugView(color: HandDrawnPalette.rugPurple)
        _ = PerspectiveRugShape()
        _ = FoodBowlView()
        _ = StudyDeskView(topColor: HandDrawnPalette.wood)
        _ = FloorLampView(isLit: false, accent: HandDrawnPalette.warmGlow)
    }
}
