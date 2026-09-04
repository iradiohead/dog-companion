import XCTest
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
}
