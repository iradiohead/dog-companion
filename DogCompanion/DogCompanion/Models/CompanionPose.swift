import Foundation
import CoreGraphics

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

    static let hidden = PoseTravel(
        x: -PosePlayback.runDistance,
        y: 0,
        scaleX: 1,
        scaleY: 1,
        rotationDegrees: 0,
        opacity: 0,
        shadowScale: 0.7,
        shadowOpacity: 0
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
            shadowOpacity: 0.16
        )
    }
}

struct PoseSnapshot: Equatable {
    var pose: CompanionPose
    var travel: PoseTravel
}

enum PosePlayback {
    static let crouchDuration: TimeInterval = 0.28
    static let jumpDuration: TimeInterval = 0.95
    static let landDuration: TimeInterval = 0.24
    static let settleDuration: TimeInterval = 0.22
    static let runDistance: CGFloat = 132
    static let jumpHeight: CGFloat = 54

    static var runningInDuration: TimeInterval {
        crouchDuration + jumpDuration + landDuration + settleDuration
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
            return jumpOnSnapshot(elapsed: elapsed, distance: distance)
        case .idle:
            return idleSnapshot(elapsed: elapsed)
        case .reacting:
            return hopSnapshot(elapsed: elapsed, height: 28, duration: 0.72)
        case .celebrating:
            return celebratingSnapshot(elapsed: elapsed)
        }
    }

    private static func jumpOnSnapshot(elapsed: TimeInterval, distance: CGFloat) -> PoseSnapshot {
        let startX = -distance
        let crouchEnd = crouchDuration
        let jumpEnd = crouchEnd + jumpDuration
        let landEnd = jumpEnd + landDuration

        if elapsed < crouchEnd {
            let t = unit(elapsed / crouchDuration)
            let crouch = smoothstep(t)
            var travel = PoseTravel.rest(
                scaleX: cg(1.0 + 0.08 * crouch),
                scaleY: cg(1.0 - 0.08 * crouch)
            )
            travel.x = startX
            travel.opacity = min(1.0, elapsed / 0.14)
            travel.shadowScale = cg(1.0 + 0.08 * crouch)
            return PoseSnapshot(pose: .sit, travel: travel)
        }

        if elapsed < jumpEnd {
            let t = unit((elapsed - crouchEnd) / jumpDuration)
            let eased = easeInOutCubic(t)
            let arc = 4.0 * t * (1.0 - t)
            var travel = PoseTravel.rest(
                scaleX: cg(0.98),
                scaleY: cg(1.05),
                rotation: cg(-5.0 * (1.0 - t))
            )
            travel.x = startX * cg(1.0 - eased)
            travel.y = -jumpHeight * cg(arc)
            travel.shadowScale = cg(1.0 - 0.32 * arc)
            travel.shadowOpacity = 0.16 * (0.55 + 0.45 * (1.0 - arc))
            return PoseSnapshot(pose: .sit, travel: travel)
        }

        if elapsed < landEnd {
            let t = unit((elapsed - jumpEnd) / landDuration)
            let recover = smoothstep(t)
            var travel = PoseTravel.rest(
                scaleX: cg(1.08 - 0.08 * recover),
                scaleY: cg(0.92 + 0.08 * recover)
            )
            travel.shadowScale = cg(1.1 - 0.1 * recover)
            return PoseSnapshot(pose: .sit, travel: travel)
        }

        let t = unit((elapsed - landEnd) / settleDuration)
        return PoseSnapshot(
            pose: .sit,
            travel: .rest(
                scaleX: cg(1.0 + 0.02 * (1.0 - t)),
                scaleY: cg(1.0 - 0.02 * (1.0 - t))
            )
        )
    }

    private static func idleSnapshot(elapsed: TimeInterval) -> PoseSnapshot {
        let breath = sin(elapsed * 1.55)
        return PoseSnapshot(
            pose: .sit,
            travel: .rest(
                scaleX: cg(1.0 - 0.008 * breath),
                scaleY: cg(1.0 + 0.01 * breath)
            )
        )
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
        return hopSnapshot(elapsed: cycle, height: 24, duration: hopLength)
    }

    private static func unit(_ value: TimeInterval) -> Double {
        min(1.0, max(0.0, value))
    }

    private static func easeInOutCubic(_ t: Double) -> Double {
        let x = unit(t)
        if x < 0.5 {
            return 4.0 * x * x * x
        }
        let y = -2.0 * x + 2.0
        return 1.0 - (y * y * y) / 2.0
    }

    private static func smoothstep(_ t: Double) -> Double {
        let clamped = unit(t)
        return clamped * clamped * (3.0 - 2.0 * clamped)
    }

    private static func cg(_ value: Double) -> CGFloat {
        CGFloat(value)
    }
}
