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
    var headY: CGFloat = 0
    var bodyY: CGFloat = 0
    var tailRotation: CGFloat = 0
    var frontLegRotation: CGFloat = 0
    var backLegRotation: CGFloat = 0
    var headRotation: CGFloat = 0
    var lean: CGFloat = 0
    var frontLegX: CGFloat = 0
    var backLegX: CGFloat = 0
    var headX: CGFloat = 0
    var bodyScaleX: CGFloat = 1
    var bodyScaleY: CGFloat = 1

    static let identity = CompanionPartTransform()
}

/// Light idle on layered PNG parts. The hop onto the mat is whole-sprite travel.
enum CompanionRigMotion {
    static func transform(state: CompanionRigState, time: TimeInterval) -> CompanionPartTransform {
        switch state {
        case .sitting:
            let breathe = sin(time)
            let tailPulse = 0.55 + 0.45 * sin(time * 0.23)
            return CompanionPartTransform(
                headY: cg(breathe * 4.0),
                bodyY: cg(breathe * 1.2),
                tailRotation: cg(sin(time * 0.7) * 0.10 * tailPulse),
                headRotation: cg(sin(time * 0.9) * 0.05),
                headX: cg(sin(time * 0.55) * 1.5),
                bodyScaleX: cg(1.0 + breathe * 0.008),
                bodyScaleY: cg(1.0 + breathe * 0.015)
            )
        case .standing:
            return CompanionPartTransform(
                headY: cg(sin(time) * 3.0),
                bodyY: cg(sin(time) * 0.8),
                tailRotation: cg(sin(time * 0.7) * 0.08),
                headRotation: cg(sin(time * 0.9) * 0.04)
            )
        case .jumping:
            return .identity
        case .walking:
            let gait = sin(time * 3.2)
            return CompanionPartTransform(
                headY: cg(sin(time * 3.2) * 3.0),
                bodyY: cg(sin(time * 3.2) * 1.2),
                tailRotation: cg(sin(time * 4.0) * 0.14),
                frontLegRotation: cg(gait * 0.22),
                backLegRotation: cg(-gait * 0.22)
            )
        case .running:
            let gait = sin(time * 8.0)
            return CompanionPartTransform(
                headY: cg(sin(time * 8.0) * 2.0),
                bodyY: cg(abs(sin(time * 8.0)) * 1.4),
                tailRotation: cg(sin(time * 10.0) * 0.16),
                frontLegRotation: cg(gait * 0.22),
                backLegRotation: cg(-gait * 0.22)
            )
        }
    }

    static func rigState(from motion: CompanionMotionState, elapsed _: TimeInterval = 0) -> CompanionRigState {
        switch motion {
        case .away, .idle, .reacting, .celebrating:
            return .sitting
        case .runningIn:
            return .jumping
        }
    }
}
