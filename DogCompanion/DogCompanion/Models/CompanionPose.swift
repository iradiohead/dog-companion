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
    var facingScaleX: CGFloat
    var rotationDegrees: CGFloat
    var opacity: Double
    var shadowScale: CGFloat
    var shadowOpacity: Double
    var occlusion: CompanionOcclusion = .seated

    static let hidden = PoseTravel(
        x: -PosePlayback.runDistance,
        y: 0,
        scaleX: 1.04,
        scaleY: 1.04,
        facingScaleX: -1,
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
            facingScaleX: 1,
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
    static let runDuration: TimeInterval = 0.92
    static let brakeDuration: TimeInterval = 0.20
    static let settleDuration: TimeInterval = 0.14
    static let runDistance: CGFloat = 168
    static var hopDistance: CGFloat { runDistance }

    static let crouchDuration: TimeInterval = 0.18
    static let jumpDuration: TimeInterval = 0.70
    static let landDuration: TimeInterval = 0.18
    static let hopFrontY: CGFloat = 0
    static let jumpHeight: CGFloat = 22

    static var runningInDuration: TimeInterval {
        runDuration + brakeDuration + settleDuration
    }

    static var climbDuration: TimeInterval {
        crouchDuration + jumpDuration + landDuration + settleDuration
    }

    static var crouchStart: TimeInterval { 0 }
    static var jumpStart: TimeInterval { crouchDuration }
    static var landStart: TimeInterval { jumpStart + jumpDuration }
    static var brakeStart: TimeInterval { runDuration }

    static func occlusion(state: CompanionMotionState, elapsed: TimeInterval) -> CompanionOcclusion {
        snapshot(state: state, elapsed: elapsed).travel.occlusion
    }

    static func pose(state: CompanionMotionState, elapsed: TimeInterval) -> CompanionPose {
        snapshot(state: state, elapsed: elapsed).pose
    }

    static func travel(
        state: CompanionMotionState,
        elapsed: TimeInterval,
        runDistance distance: CGFloat = Self.runDistance
    ) -> PoseTravel {
        snapshot(state: state, elapsed: elapsed, runDistance: distance).travel
    }

    static func snapshot(
        state: CompanionMotionState,
        elapsed: TimeInterval,
        runDistance distance: CGFloat = Self.runDistance
    ) -> PoseSnapshot {
        switch state {
        case .away:
            var travel = PoseTravel.hidden
            travel.x = -distance
            return PoseSnapshot(pose: .sit, travel: travel)
        case .runningIn:
            return runInSnapshot(elapsed: elapsed, distance: distance)
        case .idle:
            return idleSnapshot(elapsed: elapsed)
        case .reacting:
            return hopSnapshot(elapsed: elapsed, height: 22, duration: 0.72)
        case .celebrating:
            return celebratingSnapshot(elapsed: elapsed)
        }
    }

    private static func runInSnapshot(elapsed: TimeInterval, distance: CGFloat) -> PoseSnapshot {
        let runEnd = runDuration
        var travel = PoseTravel.rest()
        travel.opacity = runInOpacity(elapsed: elapsed)
        travel.occlusion = .seated

        if elapsed <= runEnd {
            let t = unit(elapsed / runDuration)
            let eased = 1.0 - pow(1.0 - t, 1.55)
            let bounce = abs(sin(elapsed * 11.0))
            let bounceAmp = 6.0 * (0.45 + 0.55 * (1.0 - t))
            let stride = 0.90 + 0.10 * bounce
            travel.facingScaleX = -1
            travel.x = -distance * cg((1.0 - eased) * stride)
            travel.y = -cg(bounce * bounceAmp)
            travel.scaleX = 1
            travel.scaleY = 1
            travel.rotationDegrees = cg(-5.0 + sin(elapsed * 11.0) * 2.5)
            travel.shadowScale = cg(1.16 - bounce * 0.24)
            travel.shadowOpacity = 0.16 + bounce * 0.06
            return PoseSnapshot(pose: .sit, travel: travel)
        }

        let settleSpan = brakeDuration + settleDuration
        let settleT = smoothstep(unit((elapsed - runEnd) / settleSpan))
        let turnDelay = min(0.10, settleSpan * 0.3)
        let bounce = abs(sin(elapsed * 11.0))
        travel.x = 0
        travel.y = -cg(bounce * 4.0 * (1.0 - settleT) * 0.25)
        travel.facingScaleX = (elapsed - runEnd) >= turnDelay ? 1 : -1
        travel.scaleX = 1
        travel.scaleY = 1
        travel.rotationDegrees = cg(lerp(-5.0, 0, settleT))
        travel.shadowScale = cg(lerp(1.08, 1.0, settleT))
        travel.shadowOpacity = lerp(0.18, 0.16, settleT)
        travel.opacity = 1
        return PoseSnapshot(pose: .sit, travel: travel)
    }

    /// Fully opaque while on screen; run-in no longer fades the owner dog in.
    static func runInOpacity(elapsed _: TimeInterval) -> Double {
        1
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

/// When the owner run flipbook replaces the mirrored sit cutout during entrance.
enum RunInPresentation {
    static func showsFlipbook(
        motion: CompanionMotionState,
        facingScaleX: CGFloat,
        hasRunFrames: Bool
    ) -> Bool {
        motion == .runningIn && facingScaleX < 0 && hasRunFrames
    }
}
