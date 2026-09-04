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
    var frontLegY: CGFloat = 0
    var backLegY: CGFloat = 0
    var frontLegScaleY: CGFloat = 1
    var backLegScaleY: CGFloat = 1
    var headX: CGFloat = 0
    var bodyScaleX: CGFloat = 1
    var bodyScaleY: CGFloat = 1

    static let identity = CompanionPartTransform()
}

/// Sliced owner cutout for idle; owner run flipbook during run-in.
enum CompanionRigMotion {
    static func transform(state: CompanionRigState, time: TimeInterval) -> CompanionPartTransform {
        switch state {
        case .sitting:
            let breathe = sin(time)
            let look = sin(time * 0.55)
            let tailPulse = 0.55 + 0.45 * sin(time * 0.23)
            return CompanionPartTransform(
                headY: cg(breathe * 3.6),
                bodyY: cg(breathe * 1.8),
                tailRotation: cg(sin(time * 1.1) * 0.12 * tailPulse),
                frontLegRotation: cg(breathe * 0.03),
                backLegRotation: cg(-breathe * 0.024),
                headRotation: cg(sin(time * 0.7) * 0.05),
                frontLegX: 0,
                backLegX: 0,
                headX: cg(look * 2.0),
                bodyScaleX: cg(1.0 + breathe * 0.01),
                bodyScaleY: cg(1.0 + breathe * 0.016)
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
            let gait = sin(time * 9.5)
            return CompanionPartTransform(
                headY: cg(1.2 + sin(time * 9.5) * 2.0),
                bodyY: cg(abs(sin(time * 9.5)) * 1.1),
                tailRotation: cg(0.06 + sin(time * 8.0) * 0.10),
                frontLegRotation: cg(gait * 0.16),
                backLegRotation: cg(-gait * 0.16),
                headRotation: cg(sin(time * 9.5) * 0.04),
                lean: -0.05,
                frontLegX: cg(gait * 3.0),
                backLegX: cg(-gait * 2.4),
                headX: cg(gait * 1.2)
            )
        }
    }

    static func transform(
        motion: CompanionMotionState,
        elapsed: TimeInterval,
        usesRunFlipbook: Bool = false
    ) -> CompanionPartTransform {
        let sitting = transform(state: .sitting, time: elapsed)
        switch motion {
        case .away, .idle, .reacting, .celebrating:
            return sitting
        case .runningIn:
            if elapsed < PosePlayback.runDuration {
                if usesRunFlipbook {
                    return runInFlipbook(elapsed: elapsed)
                }
                return runInFacingFront(elapsed: elapsed)
            }
            let running = runInFacingFront(elapsed: elapsed)
            let settleFor = PosePlayback.brakeDuration + PosePlayback.settleDuration
            let t = unit((elapsed - PosePlayback.runDuration) / settleFor)
            return mix(running, sitting, smoothstep(t))
        }
    }

    static func rigState(from motion: CompanionMotionState, elapsed: TimeInterval = 0) -> CompanionRigState {
        switch motion {
        case .away, .idle, .reacting, .celebrating:
            return .sitting
        case .runningIn:
            return .sitting
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

    private static func runInFlipbook(elapsed: TimeInterval) -> CompanionPartTransform {
        let hop = sin(elapsed * 11.0)
        let bounce = abs(hop)
        return CompanionPartTransform(
            bodyY: cg(bounce * 2.0),
            lean: -0.05,
            bodyScaleX: cg(1.0 + bounce * 0.02),
            bodyScaleY: cg(1.0 - bounce * 0.018)
        )
    }

    private static func runInFacingFront(elapsed: TimeInterval) -> CompanionPartTransform {
        let stepHz = 11.0
        let hop = sin(elapsed * stepHz)
        let bounce = abs(hop)
        let planted = 1.0 - bounce
        return CompanionPartTransform(
            headY: cg(2.0 + hop * 3.0),
            bodyY: cg(bounce * 2.6),
            tailRotation: cg(sin(elapsed * 8.0) * 0.12),
            headRotation: cg(-0.16 + hop * 0.03),
            lean: -0.05,
            frontLegY: cg(hop * 5.0),
            backLegY: cg(-hop * 4.0),
            frontLegScaleY: cg(0.90 + planted * 0.10),
            backLegScaleY: cg(0.90 + bounce * 0.10),
            headX: cg(-7.0 + hop * 1.2),
            bodyScaleX: cg(1.0 + bounce * 0.022),
            bodyScaleY: cg(1.0 - bounce * 0.018)
        )
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
            frontLegY: a.frontLegY + (b.frontLegY - a.frontLegY) * u,
            backLegY: a.backLegY + (b.backLegY - a.backLegY) * u,
            frontLegScaleY: a.frontLegScaleY + (b.frontLegScaleY - a.frontLegScaleY) * u,
            backLegScaleY: a.backLegScaleY + (b.backLegScaleY - a.backLegScaleY) * u,
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
