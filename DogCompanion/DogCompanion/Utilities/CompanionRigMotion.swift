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

/// Hand-drawn idle and jump follow-through for layered PNG parts.
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
            return jumpParts(elapsed: time)
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

    private static func jumpParts(elapsed: TimeInterval) -> CompanionPartTransform {
        let crouchEnd = PosePlayback.crouchDuration
        let jumpEnd = crouchEnd + PosePlayback.jumpDuration
        let landEnd = jumpEnd + PosePlayback.landDuration
        let coiled = CompanionPartTransform(
            headY: -6,
            bodyY: -5,
            tailRotation: -0.14,
            frontLegRotation: 0.12,
            backLegRotation: -0.10
        )
        let airborne = CompanionPartTransform(
            headY: 1,
            bodyY: 3,
            tailRotation: 0.30,
            frontLegRotation: -0.24,
            backLegRotation: 0.18
        )
        let landing = CompanionPartTransform(
            headY: 4,
            bodyY: -4,
            tailRotation: -0.06,
            frontLegRotation: 0.08,
            backLegRotation: -0.05
        )

        if elapsed <= crouchEnd {
            return mix(.identity, coiled, smoothstep(elapsed / crouchEnd))
        }
        if elapsed <= jumpEnd {
            let t = unit((elapsed - crouchEnd) / PosePlayback.jumpDuration)
            if t < 0.22 {
                return mix(coiled, airborne, smoothstep(t / 0.22))
            }
            if t < 0.5 {
                return airborne
            }
            return mix(airborne, landing, smoothstep((t - 0.5) / 0.5))
        }
        if elapsed <= landEnd {
            let t = unit((elapsed - jumpEnd) / PosePlayback.landDuration)
            return mix(landing, .identity, smoothstep(t))
        }
        return .identity
    }

    private static func mix(
        _ a: CompanionPartTransform,
        _ b: CompanionPartTransform,
        _ t: Double
    ) -> CompanionPartTransform {
        let u = CGFloat(unit(t))
        return CompanionPartTransform(
            headY: a.headY + (b.headY - a.headY) * u,
            bodyY: a.bodyY + (b.bodyY - a.bodyY) * u,
            tailRotation: a.tailRotation + (b.tailRotation - a.tailRotation) * u,
            frontLegRotation: a.frontLegRotation + (b.frontLegRotation - a.frontLegRotation) * u,
            backLegRotation: a.backLegRotation + (b.backLegRotation - a.backLegRotation) * u
        )
    }

    private static func unit(_ value: Double) -> Double {
        min(1.0, max(0.0, value))
    }

    private static func smoothstep(_ t: Double) -> Double {
        let x = unit(t)
        return x * x * (3.0 - 2.0 * x)
    }

    private static func cg(_ value: Double) -> CGFloat {
        CGFloat(value)
    }
}
