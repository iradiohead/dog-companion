import Foundation
import CoreGraphics

enum CompanionPose: String, CaseIterable, Equatable {
    case sit
    case runA
    case runB
    case land

    var promptInstruction: String {
        switch self {
        case .sit:
            return "全身坐姿居中，臀部着地，前肢直立，表情放松"
        case .runA:
            return "必须是侧面奔跑中的狗，绝对不能坐着。左前腿向前大步伸直，右后腿向后蹬地，身体前倾，四腿离地或交错迈步，像在冲向画面右侧"
        case .runB:
            return "必须是侧面奔跑中的狗，绝对不能坐着。右前腿向前大步伸直，左后腿向后蹬地，与上一跑姿相反的交叉步，身体前倾"
        case .land:
            return "必须是刚刹车的站姿，绝对不能已经坐稳。后腿弯曲、前爪撑地，身体还前倾，正在准备坐下"
        }
    }
}

struct PoseCutoutSet: Equatable {
    var sit: Data?
    var runA: Data?
    var runB: Data?
    var land: Data?

    var canFlipbook: Bool {
        runA != nil || runB != nil || land != nil
    }

    func data(for pose: CompanionPose) -> Data? {
        switch pose {
        case .sit:
            return sit
        case .runA:
            return runA ?? runB ?? sit
        case .runB:
            return runB ?? runA ?? sit
        case .land:
            return land ?? sit
        }
    }

    func withSynthesizedFallbacks() -> PoseCutoutSet {
        guard let sit else { return self }
        return PoseCutoutSet(
            sit: sit,
            runA: runA ?? PoseFrameSynthesizer.runA(from: sit),
            runB: runB ?? PoseFrameSynthesizer.runB(from: sit),
            land: land ?? PoseFrameSynthesizer.land(from: sit)
        )
    }
}

struct PoseTravel: Equatable {
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: Double
}

enum PosePlayback {
    static let runDuration: TimeInterval = 1.85
    static let landDuration: TimeInterval = 0.32
    static let strideDuration: TimeInterval = 0.11
    static let runDistance: CGFloat = 236

    static var runningInDuration: TimeInterval {
        runDuration + landDuration
    }

    static func pose(state: CompanionMotionState, elapsed: TimeInterval) -> CompanionPose {
        switch state {
        case .away:
            return .sit
        case .runningIn:
            if elapsed < runDuration {
                let frame = Int(elapsed / strideDuration)
                return frame.isMultiple(of: 2) ? .runA : .runB
            }
            if elapsed < runningInDuration {
                return .land
            }
            return .sit
        case .idle:
            return .sit
        case .reacting:
            return elapsed < 0.35 ? .land : .sit
        case .celebrating:
            let frame = Int(elapsed / 0.16) % 4
            switch frame {
            case 1: return .land
            case 2: return .runA
            default: return .sit
            }
        }
    }

    static func travel(
        state: CompanionMotionState,
        elapsed: TimeInterval,
        runDistance distance: CGFloat = Self.runDistance
    ) -> PoseTravel {
        switch state {
        case .away:
            return PoseTravel(x: -distance, y: 0, scale: 1, opacity: 0)
        case .runningIn:
            let t = min(1, elapsed / runDuration)
            let eased = 1 - (1 - t) * (1 - t)
            let hop: CGFloat
            if elapsed < runDuration {
                hop = sin(elapsed / strideDuration * .pi) * -11
            } else {
                hop = 0
            }
            return PoseTravel(
                x: -distance * (1 - eased),
                y: hop,
                scale: 1,
                opacity: 1
            )
        case .idle, .reacting, .celebrating:
            return PoseTravel(x: 0, y: 0, scale: 1, opacity: 1)
        }
    }
}
