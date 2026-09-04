import Foundation
import CoreGraphics

enum CompanionRigState: Equatable {
    case sitting
    case standing
    case jumping
    case walking
    case running
}

struct CompanionPartTransform: Equatable {
    var headY: CGFloat
    var bodyY: CGFloat
    var tailRotation: CGFloat
    var frontLegRotation: CGFloat
    var backLegRotation: CGFloat

    static let identity = CompanionPartTransform(
        headY: 0,
        bodyY: 0,
        tailRotation: 0,
        frontLegRotation: 0,
        backLegRotation: 0
    )
}

/// Hand-drawn idle and gait for layered PNG parts.
/// Sitting uses the same `sin(time)` language as a Live2D-style puppet:
/// head bob, body breathe, tail sway — not whole-sprite zoom and not a mesh warp.
enum CompanionRigMotion {
    static func transform(state: CompanionRigState, time: TimeInterval) -> CompanionPartTransform {
        switch state {
        case .sitting:
            return CompanionPartTransform(
                headY: cg(sin(time) * 5.0),
                bodyY: cg(sin(time) * 1.5),
                tailRotation: cg(sin(time * 2.0) * 0.18),
                frontLegRotation: 0,
                backLegRotation: 0
            )
        case .standing:
            return CompanionPartTransform(
                headY: cg(sin(time) * 3.0),
                bodyY: cg(sin(time) * 0.8),
                tailRotation: cg(sin(time * 1.6) * 0.12),
                frontLegRotation: 0,
                backLegRotation: 0
            )
        case .jumping:
            return .identity
        case .walking:
            let gait = sin(time * 3.2)
            return CompanionPartTransform(
                headY: cg(sin(time * 3.2) * 2.2),
                bodyY: cg(sin(time * 3.2) * 1.0),
                tailRotation: cg(sin(time * 4.0) * 0.2),
                frontLegRotation: cg(gait * 0.2),
                backLegRotation: cg(-gait * 0.2)
            )
        case .running:
            let gait = sin(time * 5.0)
            return CompanionPartTransform(
                headY: cg(sin(time * 5.0) * 2.8),
                bodyY: cg(sin(time * 5.0) * 1.4),
                tailRotation: cg(sin(time * 6.0) * 0.24),
                frontLegRotation: cg(gait * 0.28),
                backLegRotation: cg(-gait * 0.28)
            )
        }
    }

    static func rigState(from motion: CompanionMotionState) -> CompanionRigState {
        switch motion {
        case .away, .idle, .reacting, .celebrating:
            return .sitting
        case .runningIn:
            return .jumping
        }
    }

    private static func cg(_ value: Double) -> CGFloat {
        CGFloat(value)
    }
}
