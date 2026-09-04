import Foundation
import CoreGraphics

enum CompanionMotionState: Equatable {
    case away
    case runningIn
    case idle
    case reacting
    case celebrating
}

enum CompanionPose: String, CaseIterable, Equatable {
    case sit
    case runA
    case runB
    case runC
    case runD
    case land

    var promptInstruction: String {
        switch self {
        case .sit:
            return "全身坐姿居中，臀部着地，前肢直立，表情放松"
        case .runA:
            return "必须是侧面奔跑中的狗，绝对不能坐着。左前腿向前大步伸直，右后腿向后蹬地，身体前倾，四腿离地或交错迈步，像在冲向画面右侧"
        case .runB, .runC:
            return "必须是侧面奔跑中的狗，绝对不能坐着。右前腿向前大步伸直，左后腿向后蹬地，与交叉步相反，身体前倾"
        case .runD:
            return "必须是侧面奔跑中的狗，绝对不能坐着。四肢收拢准备下一次迈步，身体前倾"
        case .land:
            return "必须是刚刹车的站姿，绝对不能已经坐稳。后腿弯曲、前爪撑地，身体还前倾，正在准备坐下"
        }
    }
}

enum CompanionOcclusion: Equatable {
    case inFront
    case seated
}

struct PoseCutoutSet: Equatable {
    var sit: Data?
    var runA: Data?
    var runB: Data?
    var runC: Data? = nil
    var runD: Data? = nil
    var land: Data?

    var canFlipbook: Bool {
        runA != nil || runB != nil || runC != nil || runD != nil || land != nil
    }

    func data(for pose: CompanionPose) -> Data? {
        switch pose {
        case .sit:
            return sit
        case .runA:
            return runA ?? runB ?? sit
        case .runB:
            return runB ?? runC ?? runA ?? sit
        case .runC:
            return runC ?? runD ?? runA ?? sit
        case .runD:
            return runD ?? runA ?? sit
        case .land:
            return land ?? sit
        }
    }
}

struct PoseTravel: Equatable {
    var x: CGFloat
    var y: CGFloat
    var scaleX: CGFloat
    var scaleY: CGFloat
    var rotationDegrees: CGFloat
    var opacity: Double
    var shadowScale: CGFloat
    var shadowOpacity: Double
    var occlusion: CompanionOcclusion = .seated

    static let hidden = PoseTravel(
        x: 0,
        y: PosePlayback.hopFrontY,
        scaleX: 1.08,
        scaleY: 1.08,
        rotationDegrees: 0,
        opacity: 0,
        shadowScale: 0.85,
        shadowOpacity: 0,
        occlusion: .inFront
    )

    static func rest(scaleX: CGFloat = 1, scaleY: CGFloat = 1, rotation: CGFloat = 0) -> PoseTravel {
        PoseTravel(
            x: 0,
            y: 0,
            scaleX: scaleX,
            scaleY: scaleY,
            rotationDegrees: rotation,
            opacity: 1,
            shadowScale: 1,
            shadowOpacity: 0.16,
            occlusion: .seated
        )
    }
}

struct PoseSnapshot: Equatable {
    var pose: CompanionPose
    var travel: PoseTravel
}

enum PosePlayback {
    static let crouchDuration: TimeInterval = 0.18
    static let jumpDuration: TimeInterval = 0.70
    static let landDuration: TimeInterval = 0.18
    static let settleDuration: TimeInterval = 0.14
    static let hopFrontY: CGFloat = 68
    static var hopDistance: CGFloat { hopFrontY }
    static let jumpHeight: CGFloat = 58
    static var runDistance: CGFloat { hopFrontY }

    static var runningInDuration: TimeInterval {
        crouchDuration + jumpDuration + landDuration + settleDuration
    }

    static var crouchStart: TimeInterval { 0 }
    static var jumpStart: TimeInterval { crouchDuration }
    static var landStart: TimeInterval { jumpStart + jumpDuration }

    static func occlusion(state: CompanionMotionState, elapsed: TimeInterval) -> CompanionOcclusion {
        snapshot(state: state, elapsed: elapsed).travel.occlusion
    }

    static func pose(state: CompanionMotionState, elapsed: TimeInterval) -> CompanionPose {
        snapshot(state: state, elapsed: elapsed).pose
    }

    static func travel(
        state: CompanionMotionState,
        elapsed: TimeInterval,
        runDistance distance: CGFloat = Self.hopFrontY
    ) -> PoseTravel {
        snapshot(state: state, elapsed: elapsed, runDistance: distance).travel
    }

    static func snapshot(
        state: CompanionMotionState,
        elapsed: TimeInterval,
        runDistance distance: CGFloat = Self.hopFrontY
    ) -> PoseSnapshot {
        switch state {
        case .away:
            var travel = PoseTravel.hidden
            travel.y = distance
            return PoseSnapshot(pose: .sit, travel: travel)
        case .runningIn:
            return hopOnSnapshot(elapsed: elapsed, distance: distance)
        case .idle:
            return idleSnapshot(elapsed: elapsed)
        case .reacting:
            return hopSnapshot(elapsed: elapsed, height: 22, duration: 0.72)
        case .celebrating:
            return celebratingSnapshot(elapsed: elapsed)
        }
    }

    private static func hopOnSnapshot(elapsed: TimeInterval, distance: CGFloat) -> PoseSnapshot {
        let startY = distance
        let crouchEnd = crouchDuration
        let jumpEnd = crouchEnd + jumpDuration
        let landEnd = jumpEnd + landDuration
        var travel = PoseTravel.rest()
        travel.opacity = min(1.0, elapsed / 0.12)
        travel.occlusion = elapsed < jumpStart + jumpDuration * 0.52 ? .inFront : .seated

        if elapsed <= crouchEnd {
            let crouch = smoothstep(elapsed / crouchDuration)
            travel.x = 0
            travel.y = startY
            travel.scaleX = cg(lerp(1.04, 1.10, crouch))
            travel.scaleY = cg(lerp(1.04, 0.92, crouch))
            travel.rotationDegrees = cg(lerp(0, 4.0, crouch))
            travel.shadowScale = cg(lerp(1.12, 1.22, crouch))
            return PoseSnapshot(pose: .sit, travel: travel)
        }

        if elapsed <= jumpEnd {
            let t = unit((elapsed - crouchEnd) / jumpDuration)
            let arc = sin(Double.pi * t)
            travel.x = 0
            travel.y = startY * cg(1.0 - t) - jumpHeight * cg(arc)
            if t < 0.28 {
                let u = smoothstep(t / 0.28)
                travel.scaleX = cg(lerp(1.10, 0.97, u))
                travel.scaleY = cg(lerp(0.92, 1.08, u))
                travel.rotationDegrees = cg(lerp(4.0, -6.0, u))
            } else {
                let u = smoothstep((t - 0.28) / 0.72)
                travel.scaleX = cg(lerp(0.97, 1.06, u))
                travel.scaleY = cg(lerp(1.08, 0.94, u))
                travel.rotationDegrees = cg(lerp(-6.0, 3.0, u))
            }
            travel.shadowScale = cg(lerp(1.22, 1.0, t) - 0.28 * arc)
            travel.shadowOpacity = 0.16 * (0.4 + 0.6 * (1.0 - arc))
            return PoseSnapshot(pose: .sit, travel: travel)
        }

        if elapsed <= landEnd {
            let t = unit((elapsed - jumpEnd) / landDuration)
            travel.x = 0
            travel.y = 0
            if t < 0.45 {
                let u = smoothstep(t / 0.45)
                travel.scaleX = cg(lerp(1.06, 1.10, u))
                travel.scaleY = cg(lerp(0.94, 0.88, u))
                travel.rotationDegrees = cg(lerp(3.0, 2.0, u))
            } else {
                let u = smoothstep((t - 0.45) / 0.55)
                travel.scaleX = cg(lerp(1.10, 1.02, u))
                travel.scaleY = cg(lerp(0.88, 0.98, u))
                travel.rotationDegrees = cg(lerp(2.0, 0.5, u))
            }
            travel.shadowScale = cg(lerp(1.14, 1.04, t))
            return PoseSnapshot(pose: .sit, travel: travel)
        }

        let settle = smoothstep(unit((elapsed - landEnd) / settleDuration))
        return PoseSnapshot(
            pose: .sit,
            travel: .rest(
                scaleX: cg(lerp(1.02, 1.0, settle)),
                scaleY: cg(lerp(0.98, 1.0, settle)),
                rotation: cg(lerp(0.5, 0, settle))
            )
        )
    }

    private static func idleSnapshot(elapsed _: TimeInterval) -> PoseSnapshot {
        PoseSnapshot(pose: .sit, travel: .rest())
    }

    private static func hopSnapshot(elapsed: TimeInterval, height: CGFloat, duration: TimeInterval) -> PoseSnapshot {
        let t = unit(elapsed / duration)
        if t < 0.18 {
            let c = unit(t / 0.18)
            return PoseSnapshot(
                pose: .sit,
                travel: .rest(
                    scaleX: cg(1.0 + 0.06 * c),
                    scaleY: cg(1.0 - 0.06 * c)
                )
            )
        }
        if t < 0.72 {
            let a = unit((t - 0.18) / 0.54)
            let arc = 4.0 * a * (1.0 - a)
            var travel = PoseTravel.rest(scaleX: 0.99, scaleY: 1.04)
            travel.y = -height * cg(arc)
            travel.shadowScale = cg(1.0 - 0.28 * arc)
            return PoseSnapshot(pose: .sit, travel: travel)
        }
        let c = unit((t - 0.72) / 0.28)
        return PoseSnapshot(
            pose: .sit,
            travel: .rest(
                scaleX: cg(1.05 - 0.05 * c),
                scaleY: cg(0.95 + 0.05 * c)
            )
        )
    }

    private static func celebratingSnapshot(elapsed: TimeInterval) -> PoseSnapshot {
        let hopLength: TimeInterval = 0.78
        if elapsed >= hopLength * 2.0 {
            return idleSnapshot(elapsed: elapsed)
        }
        let cycle = elapsed.truncatingRemainder(dividingBy: hopLength)
        return hopSnapshot(elapsed: cycle, height: 20, duration: hopLength)
    }

    private static func unit(_ value: TimeInterval) -> Double {
        min(1.0, max(0.0, value))
    }

    private static func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * unit(t)
    }

    private static func smoothstep(_ t: Double) -> Double {
        let clamped = unit(t)
        return clamped * clamped * (3.0 - 2.0 * clamped)
    }

    private static func cg(_ value: Double) -> CGFloat {
        CGFloat(value)
    }
}
