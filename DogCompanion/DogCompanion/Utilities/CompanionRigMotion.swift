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

/// Hand-drawn idle and run follow-through for layered PNG parts.
enum CompanionRigMotion {
    static func transform(state: CompanionRigState, time: TimeInterval) -> CompanionPartTransform {
        switch state {
        case .sitting:
            return CompanionPartTransform(
                headY: cg(sin(time) * 16.0),
                bodyY: cg(sin(time) * 5.0),
                tailRotation: cg(sin(time * 2.0) * 0.28),
                headRotation: cg(sin(time * 1.15) * 0.20),
                headX: cg(sin(time * 0.85) * 6.0),
                bodyScaleX: cg(1.0 + sin(time) * 0.03),
                bodyScaleY: cg(1.0 + sin(time) * 0.07)
            )
        case .standing:
            return CompanionPartTransform(
                headY: cg(sin(time) * 10.0),
                bodyY: cg(sin(time) * 3.0),
                tailRotation: cg(sin(time * 1.6) * 0.18),
                headRotation: cg(sin(time * 1.1) * 0.12),
                headX: cg(sin(time * 0.9) * 4.0),
                bodyScaleX: cg(1.0 + sin(time) * 0.02),
                bodyScaleY: cg(1.0 + sin(time) * 0.05)
            )
        case .jumping:
            return jumpParts(elapsed: time)
        case .walking:
            let gait = sin(time * 3.2)
            return CompanionPartTransform(
                headY: cg(sin(time * 3.2) * 8.0),
                bodyY: cg(sin(time * 3.2) * 3.0),
                tailRotation: cg(sin(time * 4.0) * 0.24),
                frontLegRotation: cg(gait * 0.40),
                backLegRotation: cg(-gait * 0.40),
                headRotation: cg(sin(time * 3.2) * 0.14),
                lean: -0.14,
                frontLegX: cg(gait * 10.0),
                backLegX: cg(-gait * 9.0),
                headX: cg(4.0 + gait * 3.0),
                bodyScaleX: 1.08,
                bodyScaleY: 0.92
            )
        case .running:
            let gait = sin(time * 8.0)
            return CompanionPartTransform(
                headY: cg(10.0 + sin(time * 8.0) * 12.0),
                bodyY: cg(12.0 + abs(sin(time * 8.0)) * 6.0),
                tailRotation: cg(0.22 + sin(time * 10.0) * 0.32),
                frontLegRotation: cg(gait * 0.70),
                backLegRotation: cg(-gait * 0.70),
                headRotation: cg(-0.10 + sin(time * 8.0) * 0.22),
                lean: -0.24,
                frontLegX: cg(gait * 18.0),
                backLegX: cg(-gait * 16.0),
                headX: cg(10.0 + gait * 5.0),
                bodyScaleX: 1.22,
                bodyScaleY: 0.78
            )
        }
    }

    static func rigState(from motion: CompanionMotionState, elapsed: TimeInterval = 0) -> CompanionRigState {
        switch motion {
        case .away, .idle, .reacting, .celebrating:
            return .sitting
        case .runningIn:
            return elapsed < PosePlayback.runDuration ? .running : .jumping
        }
    }

    private static func jumpParts(elapsed: TimeInterval) -> CompanionPartTransform {
        let local = elapsed - PosePlayback.runDuration
        let crouchEnd = PosePlayback.crouchDuration
        let jumpEnd = crouchEnd + PosePlayback.jumpDuration
        let landEnd = jumpEnd + PosePlayback.landDuration
        let coiled = CompanionPartTransform(
            headY: -10,
            bodyY: -6,
            tailRotation: -0.14,
            frontLegRotation: 0.12,
            backLegRotation: -0.10,
            headRotation: -0.10,
            headX: 2,
            bodyScaleX: 1.10,
            bodyScaleY: 0.88
        )
        let airborne = CompanionPartTransform(
            headY: 4,
            bodyY: 4,
            tailRotation: 0.30,
            frontLegRotation: -0.28,
            backLegRotation: 0.22,
            headRotation: 0.08,
            headX: 6,
            bodyScaleX: 0.94,
            bodyScaleY: 1.08
        )
        let landing = CompanionPartTransform(
            headY: 6,
            bodyY: -4,
            tailRotation: -0.06,
            frontLegRotation: 0.08,
            backLegRotation: -0.05,
            headRotation: 0.04,
            bodyScaleX: 1.08,
            bodyScaleY: 0.90
        )

        if local <= 0 {
            return transform(state: .running, time: elapsed)
        }
        if local <= crouchEnd {
            let fromRun = transform(state: .running, time: PosePlayback.runDuration)
            return mix(fromRun, coiled, smoothstep(local / crouchEnd))
        }
        if local <= jumpEnd {
            let t = unit((local - crouchEnd) / PosePlayback.jumpDuration)
            if t < 0.22 {
                return mix(coiled, airborne, smoothstep(t / 0.22))
            }
            if t < 0.5 {
                return airborne
            }
            return mix(airborne, landing, smoothstep((t - 0.5) / 0.5))
        }
        if local <= landEnd {
            let t = unit((local - jumpEnd) / PosePlayback.landDuration)
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
            backLegRotation: a.backLegRotation + (b.backLegRotation - a.backLegRotation) * u,
            headRotation: a.headRotation + (b.headRotation - a.headRotation) * u,
            lean: a.lean + (b.lean - a.lean) * u,
            frontLegX: a.frontLegX + (b.frontLegX - a.frontLegX) * u,
            backLegX: a.backLegX + (b.backLegX - a.backLegX) * u,
            headX: a.headX + (b.headX - a.headX) * u,
            bodyScaleX: a.bodyScaleX + (b.bodyScaleX - a.bodyScaleX) * u,
            bodyScaleY: a.bodyScaleY + (b.bodyScaleY - a.bodyScaleY) * u
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
