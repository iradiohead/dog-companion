import Foundation

enum FocusSessionPhase: Equatable {
    case idle
    case running
    case paused
    case completed
}

struct FocusSessionConfig {
    static let defaultDuration: TimeInterval = 25 * 60
    static let tickInterval: TimeInterval = 1
}
