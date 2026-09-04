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
            return "侧面全身奔跑，左前腿向前大步迈出，右后腿向后蹬地，身体明显前倾，四腿交错"
        case .runB:
            return "侧面全身奔跑，右前腿向前大步迈出，左后腿向后蹬地，与交叉步相反，身体前倾"
        case .land:
            return "全身刚跑到停下，后腿弯曲下蹲、前爪点地，正在坐下但尚未完全坐稳"
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
}

struct PoseTravel: Equatable {
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: Double
}

enum PosePlayback {
    static let runDuration: TimeInterval = 1.24
    static let landDuration: TimeInterval = 0.28
    static let strideDuration: TimeInterval = 0.12

    static func pose(state: CompanionMotionState, elapsed: TimeInterval) -> CompanionPose {
        switch state {
        case .away:
            return .sit
        case .runningIn:
            if elapsed < runDuration {
                let frame = Int(elapsed / strideDuration)
                return frame.isMultiple(of: 2) ? .runA : .runB
            }
            if elapsed < runDuration + landDuration {
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

    static func travel(state: CompanionMotionState, elapsed: TimeInterval) -> PoseTravel {
        switch state {
        case .away:
            return PoseTravel(x: 170, y: -58, scale: 0.3, opacity: 0)
        case .runningIn:
            let t = min(1, elapsed / runDuration)
            let eased = 1 - (1 - t) * (1 - t)
            return PoseTravel(
                x: 170 * (1 - eased),
                y: -58 * (1 - eased),
                scale: 0.34 + 0.66 * eased,
                opacity: 1
            )
        case .idle, .reacting, .celebrating:
            return PoseTravel(x: 0, y: 0, scale: 1, opacity: 1)
        }
    }
}
