import Foundation
import SwiftUI
import SwiftData

@Observable
@MainActor
final class HomeViewModel {
    private(set) var showFeedAnimation = false
    private(set) var showPlayAnimation = false
    private(set) var showWalkAnimation = false

    func refreshDecay(for companion: Companion) {
        let result = VitalStatsCalculator.applyDecay(
            hunger: companion.hunger,
            mood: companion.mood,
            lastUpdated: companion.lastUpdated
        )

        if result.hunger != companion.hunger || result.mood != companion.mood {
            companion.hunger = result.hunger
            companion.mood = result.mood
            companion.lastUpdated = .now
        }
    }

    func feed(_ companion: Companion) {
        companion.hunger = VitalStatsCalculator.feed(hunger: companion.hunger)
        companion.lastUpdated = .now
        triggerAnimation(\.showFeedAnimation)
    }

    func play(_ companion: Companion) {
        companion.mood = VitalStatsCalculator.play(mood: companion.mood)
        companion.lastUpdated = .now
        triggerAnimation(\.showPlayAnimation)
    }

    func walk(_ companion: Companion) {
        let result = VitalStatsCalculator.walk(hunger: companion.hunger, mood: companion.mood)
        companion.hunger = result.hunger
        companion.mood = result.mood
        companion.lastUpdated = .now
        triggerAnimation(\.showWalkAnimation)
    }

    private func triggerAnimation(_ keyPath: ReferenceWritableKeyPath<HomeViewModel, Bool>) {
        self[keyPath: keyPath] = true
        Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            self[keyPath: keyPath] = false
        }
    }
}
