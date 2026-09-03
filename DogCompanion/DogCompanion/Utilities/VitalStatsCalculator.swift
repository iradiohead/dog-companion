import Foundation

enum ExpressionTier: Int, CaseIterable {
    case excellent = 5
    case good = 4
    case okay = 3
    case low = 2
    case critical = 1

    init(value: Int) {
        switch value {
        case 81...100: self = .excellent
        case 61...80: self = .good
        case 41...60: self = .okay
        case 21...40: self = .low
        default: self = .critical
        }
    }

    var emoji: String {
        switch self {
        case .excellent: return "😄"
        case .good: return "🙂"
        case .okay: return "😐"
        case .low: return "😟"
        case .critical: return "😢"
        }
    }

    var label: String {
        switch self {
        case .excellent: return "非常好"
        case .good: return "不错"
        case .okay: return "一般"
        case .low: return "偏低"
        case .critical: return "很差"
        }
    }
}

enum VitalStatsCalculator {
    static let hungerDecayInterval: TimeInterval = 4 * 60 * 60
    static let moodDecayInterval: TimeInterval = 6 * 60 * 60
    static let decayAmount = 20

    static func applyDecay(hunger: Int, mood: Int, lastUpdated: Date, now: Date = .now) -> (hunger: Int, mood: Int) {
        let elapsed = now.timeIntervalSince(lastUpdated)
        guard elapsed > 0 else { return (hunger, mood) }

        let hungerTicks = Int(elapsed / hungerDecayInterval)
        let moodTicks = Int(elapsed / moodDecayInterval)

        let newHunger = clamp(hunger - hungerTicks * decayAmount)
        let newMood = clamp(mood - moodTicks * decayAmount)
        return (newHunger, newMood)
    }

    static func clamp(_ value: Int) -> Int {
        min(100, max(0, value))
    }

    static func feed(hunger: Int) -> Int {
        clamp(hunger + 30)
    }

    static func play(mood: Int) -> Int {
        clamp(mood + 30)
    }

    static func walk(hunger: Int, mood: Int) -> (hunger: Int, mood: Int) {
        (clamp(hunger - 10), clamp(mood + 20))
    }
}
