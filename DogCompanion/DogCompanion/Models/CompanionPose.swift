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

    func withSynthesizedFallbacks() -> PoseCutoutSet {
        guard let sit else { return self }
        let cycle = PoseFrameSynthesizer.runCycle(from: sit)
        return PoseCutoutSet(
            sit: sit,
            runA: cycle.count > 0 ? cycle[0] : nil,
            runB: cycle.count > 1 ? cycle[1] : nil,
            runC: cycle.count > 2 ? cycle[2] : nil,
            runD: cycle.count > 3 ? cycle[3] : nil,
            land: PoseFrameSynthesizer.land(from: sit) ?? land
        )
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
    var motion: Double
    var dust: Double

    static let hidden = PoseTravel(
        x: -PosePlayback.runDistance,
        y: 0,
        scaleX: 1,
        scaleY: 1,
        rotationDegrees: 0,
        opacity: 0,
        shadowScale: 0.7,
        shadowOpacity: 0,
        motion: 0,
        dust: 0
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
            shadowOpacity: 0.18,
            motion: 0,
            dust: 0
        )
    }
}

struct PoseSnapshot: Equatable {
    var pose: CompanionPose
    var nextPose: CompanionPose
    var crossfade: Double
    var travel: PoseTravel
}

enum PosePlayback {
    static let anticipateDuration: TimeInterval = 0.18
    static let runDuration: TimeInterval = 1.42
    static let landDuration: TimeInterval = 0.32
    static let settleDuration: TimeInterval = 0.40
    static let strideDuration: TimeInterval = 0.11
    static let runDistance: CGFloat = 236
    static let windup: CGFloat = 14
    static let hopHeight: CGFloat = 18

    static var runningInDuration: TimeInterval {
        anticipateDuration + runDuration + landDuration + settleDuration
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
            return PoseSnapshot(pose: .sit, nextPose: .sit, crossfade: 0, travel: travel)
        case .runningIn:
            return runningInSnapshot(elapsed: elapsed, distance: distance)
        case .idle:
            return idleSnapshot(elapsed: elapsed)
        case .reacting:
            return reactingSnapshot(elapsed: elapsed)
        case .celebrating:
            return celebratingSnapshot(elapsed: elapsed)
        }
    }

    private static func runningInSnapshot(elapsed: TimeInterval, distance: CGFloat) -> PoseSnapshot {
        let startX = -distance - windup
        let anticipateEnd = anticipateDuration
        let runEnd = anticipateEnd + runDuration
        let landEnd = runEnd + landDuration

        if elapsed < anticipateEnd {
            let t = unit(elapsed / anticipateDuration)
            let crouch = smoothstep(t)
            var travel = PoseTravel.rest(
                scaleX: cg(1 + 0.2 * crouch),
                scaleY: cg(1 - 0.22 * crouch),
                rotation: cg(-14.0 * crouch)
            )
            travel.x = -distance - windup * cg(crouch)
            travel.opacity = min(1.0, elapsed / 0.07)
            travel.shadowScale = cg(1.08 + 0.12 * crouch)
            travel.shadowOpacity = 0.22
            return PoseSnapshot(pose: .sit, nextPose: .sit, crossfade: 0, travel: travel)
        }

        if elapsed < runEnd {
            let runElapsed = elapsed - anticipateEnd
            let t = unit(runElapsed / runDuration)
            let eased = easeOutCubic(t)
            let gait = gallop(runElapsed: runElapsed)
            var travel = PoseTravel.rest(scaleX: gait.sx, scaleY: gait.sy, rotation: gait.rot)
            travel.x = startX * cg(1.0 - eased)
            travel.y = gait.y
            travel.motion = gait.motion
            travel.dust = gait.dust
            let hopAmount = min(1.0, max(0.0, Double(-gait.y) / Double(hopHeight)))
            travel.shadowScale = cg(1.05 - 0.42 * hopAmount)
            travel.shadowOpacity = 0.18 * (0.45 + 0.55 * (1.0 - hopAmount))
            let stride = strideBlend(runElapsed: runElapsed)
            return PoseSnapshot(
                pose: stride.pose,
                nextPose: stride.next,
                crossfade: stride.crossfade,
                travel: travel
            )
        }

        if elapsed < landEnd {
            let t = unit((elapsed - runEnd) / landDuration)
            let recover = easeOutCubic(t)
            var travel = PoseTravel.rest(
                scaleX: cg(1.24 - 0.16 * recover),
                scaleY: cg(0.72 + 0.2 * recover),
                rotation: cg(-8.0 + 12.0 * recover)
            )
            travel.x = cg(5.0 * (1.0 - recover) * sin(t * .pi))
            travel.dust = (1.0 - t) * 0.85
            travel.shadowScale = cg(1.22 - 0.14 * recover)
            travel.shadowOpacity = 0.24
            return PoseSnapshot(
                pose: .land,
                nextPose: .sit,
                crossfade: 0.35 * t,
                travel: travel
            )
        }

        let t = unit((elapsed - landEnd) / settleDuration)
        let bounce = sin(t * .pi) * (1.0 - t)
        var travel = PoseTravel.rest(
            scaleX: cg(1.0 + 0.07 * bounce),
            scaleY: cg(1.0 - 0.05 * bounce),
            rotation: cg(4.0 * (1.0 - t))
        )
        if t >= 0.98 {
            return PoseSnapshot(pose: .sit, nextPose: .sit, crossfade: 0, travel: .rest())
        }
        return PoseSnapshot(
            pose: .land,
            nextPose: .sit,
            crossfade: smoothstep(t),
            travel: travel
        )
    }

    private static func idleSnapshot(elapsed: TimeInterval) -> PoseSnapshot {
        let breath = sin(elapsed * 2.15)
        return PoseSnapshot(
            pose: .sit,
            nextPose: .sit,
            crossfade: 0,
            travel: .rest(
                scaleX: cg(1.0 - 0.012 * breath),
                scaleY: cg(1.0 + 0.018 * breath)
            )
        )
    }

    private static func reactingSnapshot(elapsed: TimeInterval) -> PoseSnapshot {
        if elapsed < 0.1 {
            let t = unit(elapsed / 0.1)
            return PoseSnapshot(
                pose: .sit,
                nextPose: .land,
                crossfade: t * 0.4,
                travel: .rest(
                    scaleX: cg(1.0 + 0.14 * t),
                    scaleY: cg(1.0 - 0.16 * t),
                    rotation: cg(-6.0 * t)
                )
            )
        }
        if elapsed < 0.42 {
            let t = unit((elapsed - 0.1) / 0.32)
            let hop = 4.0 * t * (1.0 - t)
            var travel = PoseTravel.rest(
                scaleX: 0.94,
                scaleY: 1.08,
                rotation: -10
            )
            travel.y = cg(-22.0 * hop)
            travel.shadowScale = cg(1.0 - 0.35 * hop)
            travel.motion = 0.25
            return PoseSnapshot(pose: .land, nextPose: .land, crossfade: 0, travel: travel)
        }
        if elapsed < 0.72 {
            let t = unit((elapsed - 0.42) / 0.3)
            return PoseSnapshot(
                pose: .land,
                nextPose: .sit,
                crossfade: smoothstep(t),
                travel: .rest(
                    scaleX: cg(1.12 - 0.12 * t),
                    scaleY: cg(0.86 + 0.14 * t)
                )
            )
        }
        return idleSnapshot(elapsed: elapsed - 0.72)
    }

    private static func celebratingSnapshot(elapsed: TimeInterval) -> PoseSnapshot {
        let period: TimeInterval = 0.4
        let cycle = elapsed.truncatingRemainder(dividingBy: period)
        if cycle < 0.12 {
            let t = unit(cycle / 0.12)
            return PoseSnapshot(
                pose: .sit,
                nextPose: .land,
                crossfade: t * 0.5,
                travel: .rest(
                    scaleX: cg(1.0 + 0.12 * t),
                    scaleY: cg(1.0 - 0.14 * t)
                )
            )
        }
        if cycle < 0.3 {
            let t = unit((cycle - 0.12) / 0.18)
            let hop = 4.0 * t * (1.0 - t)
            var travel = PoseTravel.rest(scaleX: 0.95, scaleY: 1.08, rotation: -8)
            travel.y = cg(-20.0 * hop)
            travel.shadowScale = cg(1.0 - 0.4 * hop)
            return PoseSnapshot(pose: .land, nextPose: .runA, crossfade: hop * 0.25, travel: travel)
        }
        let t = unit((cycle - 0.3) / 0.1)
        return PoseSnapshot(
            pose: .land,
            nextPose: .sit,
            crossfade: t,
            travel: .rest(
                scaleX: cg(1.1 - 0.1 * t),
                scaleY: cg(0.9 + 0.1 * t)
            )
        )
    }

    private static func gallop(runElapsed: TimeInterval) -> (y: CGFloat, sx: CGFloat, sy: CGFloat, rot: CGFloat, dust: Double, motion: Double) {
        let u = runElapsed.truncatingRemainder(dividingBy: strideDuration) / strideDuration
        let contactEnd = 0.26
        if u < contactEnd {
            let c = u / contactEnd
            return (
                y: 0,
                sx: cg(1.06 - 0.04 * c),
                sy: cg(0.94 + 0.04 * c),
                rot: cg(-8.0 - 2.0 * c),
                dust: (1.0 - c) * 0.95,
                motion: 0.5 + 0.4 * c
            )
        }
        let a = (u - contactEnd) / (1.0 - contactEnd)
        let hop = 4.0 * a * (1.0 - a)
        return (
            y: -hopHeight * cg(hop),
            sx: cg(0.98),
            sy: cg(1.03 + 0.03 * hop),
            rot: cg(-10.0 + 3.0 * a),
            dust: 0,
            motion: 0.9
        )
    }

    private static func strideBlend(runElapsed: TimeInterval) -> (pose: CompanionPose, next: CompanionPose, crossfade: Double) {
        let frames: [CompanionPose] = [.runA, .runB, .runC, .runD]
        let index = Int(runElapsed / strideDuration)
        let u = runElapsed.truncatingRemainder(dividingBy: strideDuration) / strideDuration
        let pose = frames[index % frames.count]
        let next = frames[(index + 1) % frames.count]
        let crossfade = smoothstep((u - 0.78) / 0.22)
        return (pose, next, crossfade)
    }

    private static func unit(_ value: TimeInterval) -> Double {
        min(1.0, max(0.0, value))
    }

    private static func easeOutCubic(_ t: Double) -> Double {
        let clamped = unit(t)
        return 1.0 - pow(1.0 - clamped, 3.0)
    }

    private static func smoothstep(_ t: Double) -> Double {
        let clamped = unit(t)
        return clamped * clamped * (3.0 - 2.0 * clamped)
    }

    private static func cg(_ value: Double) -> CGFloat {
        CGFloat(value)
    }
}
