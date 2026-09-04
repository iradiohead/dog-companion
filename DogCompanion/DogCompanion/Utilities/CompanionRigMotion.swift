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

/// Layered PNG puppet. Idle and the climb onto the mat both move head, body, legs, and tail.
enum CompanionRigMotion {
    static func transform(state: CompanionRigState, time: TimeInterval) -> CompanionPartTransform {
        switch state {
        case .sitting:
            let breathe = sin(time)
            let look = sin(time * 0.55)
            let tailPulse = 0.55 + 0.45 * sin(time * 0.23)
            return CompanionPartTransform(
                headY: cg(breathe * 8.0),
                bodyY: cg(breathe * 2.4),
                tailRotation: cg(sin(time * 1.1) * 0.20 * tailPulse),
                frontLegRotation: cg(breathe * 0.06),
                backLegRotation: cg(-breathe * 0.05),
                headRotation: cg(sin(time * 0.9) * 0.10),
                frontLegX: cg(breathe * 2.0),
                backLegX: cg(-breathe * 1.6),
                headX: cg(look * 4.0),
                bodyScaleX: cg(1.0 + breathe * 0.02),
                bodyScaleY: cg(1.0 + breathe * 0.035)
            )
        case .standing:
            return CompanionPartTransform(
                headY: cg(sin(time) * 5.0),
                bodyY: cg(sin(time) * 1.4),
                tailRotation: cg(sin(time * 1.1) * 0.14),
                frontLegRotation: cg(sin(time) * 0.04),
                backLegRotation: cg(-sin(time) * 0.04),
                headRotation: cg(sin(time * 0.9) * 0.07),
                headX: cg(sin(time * 0.55) * 3.0)
            )
        case .jumping:
            return climbParts(elapsed: time)
        case .walking:
            let gait = sin(time * 3.2)
            return CompanionPartTransform(
                headY: cg(sin(time * 3.2) * 5.0),
                bodyY: cg(sin(time * 3.2) * 2.0),
                tailRotation: cg(sin(time * 4.0) * 0.22),
                frontLegRotation: cg(gait * 0.38),
                backLegRotation: cg(-gait * 0.38),
                headRotation: cg(sin(time * 3.2) * 0.10),
                lean: -0.08,
                frontLegX: cg(gait * 8.0),
                backLegX: cg(-gait * 7.0),
                headX: cg(gait * 3.0)
            )
        case .running:
            let gait = sin(time * 6.0)
            return CompanionPartTransform(
                headY: cg(6.0 + sin(time * 6.0) * 8.0),
                bodyY: cg(abs(sin(time * 6.0)) * 3.0),
                tailRotation: cg(0.16 + sin(time * 7.0) * 0.24),
                frontLegRotation: cg(gait * 0.48),
                backLegRotation: cg(-gait * 0.48),
                headRotation: cg(sin(time * 6.0) * 0.12),
                lean: -0.14,
                frontLegX: cg(gait * 12.0),
                backLegX: cg(-gait * 10.0),
                headX: cg(6.0 + gait * 4.0)
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

    static func eyeScale(time: TimeInterval) -> CGFloat {
        let period = 3.4
        let cycle = time.truncatingRemainder(dividingBy: period)
        if cycle > period - 0.12 {
            return 0.12
        }
        return 1
    }

    private static func climbParts(elapsed: TimeInterval) -> CompanionPartTransform {
        let crouchEnd = PosePlayback.crouchDuration
        let jumpEnd = crouchEnd + PosePlayback.jumpDuration
        let landEnd = jumpEnd + PosePlayback.landDuration
        let plant = CompanionPartTransform(
            headY: -14,
            bodyY: -9,
            tailRotation: -0.28,
            frontLegRotation: 0.42,
            backLegRotation: -0.34,
            headRotation: -0.18,
            lean: 0.10,
            frontLegX: 8,
            backLegX: -10,
            headX: 3,
            bodyScaleX: 1.14,
            bodyScaleY: 0.84
        )
        let launch = CompanionPartTransform(
            headY: 10,
            bodyY: 5,
            tailRotation: 0.40,
            frontLegRotation: -0.62,
            backLegRotation: 0.50,
            headRotation: 0.14,
            lean: -0.20,
            frontLegX: -6,
            backLegX: 10,
            headX: 5,
            bodyScaleX: 0.88,
            bodyScaleY: 1.16
        )
        let airborne = CompanionPartTransform(
            headY: 8,
            bodyY: 7,
            tailRotation: 0.48,
            frontLegRotation: -0.46,
            backLegRotation: 0.36,
            headRotation: 0.10,
            lean: -0.12,
            frontLegX: -3,
            backLegX: 7,
            headX: 4,
            bodyScaleX: 0.92,
            bodyScaleY: 1.10
        )
        let landing = CompanionPartTransform(
            headY: 5,
            bodyY: -7,
            tailRotation: -0.16,
            frontLegRotation: 0.28,
            backLegRotation: -0.22,
            headRotation: 0.08,
            lean: 0.08,
            frontLegX: 5,
            backLegX: -5,
            headX: 1,
            bodyScaleX: 1.12,
            bodyScaleY: 0.86
        )

        if elapsed <= crouchEnd {
            return mix(.identity, plant, smoothstep(elapsed / crouchEnd))
        }
        if elapsed <= jumpEnd {
            let t = unit((elapsed - crouchEnd) / PosePlayback.jumpDuration)
            if t < 0.22 {
                return mix(plant, launch, smoothstep(t / 0.22))
            }
            if t < 0.55 {
                return mix(launch, airborne, smoothstep((t - 0.22) / 0.33))
            }
            return mix(airborne, landing, smoothstep((t - 0.55) / 0.45))
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
