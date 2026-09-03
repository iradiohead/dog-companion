import Foundation

enum RegenerationPolicy {
    static let maxAllowed = 3

    static func canRegenerate(usedCount: Int) -> Bool {
        usedCount < maxAllowed
    }

    static func remaining(usedCount: Int) -> Int {
        max(0, maxAllowed - usedCount)
    }
}
