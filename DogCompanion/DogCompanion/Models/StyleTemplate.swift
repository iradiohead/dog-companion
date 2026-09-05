import Foundation
import SwiftData

/// The app uses one hand-drawn illustration look for every companion.
enum StyleTemplate: String, Codable {
    case handDrawn

    /// Legacy stored values map to the unified hand-drawn style.
    init?(rawValue: String) {
        switch rawValue {
        case Self.handDrawn.rawValue, "anime", "flatCartoon", "watercolor":
            self = .handDrawn
        default:
            return nil
        }
    }

    static let `default` = StyleTemplate.handDrawn

    var displayName: String { "手绘" }

    var iconName: String { "paintbrush.pointed" }

    var shortDescription: String { "温暖手绘线条，保留照片里那只狗" }

    var prompt: String {
        prompt(for: .sit)
    }

    func prompt(for pose: CompanionPose) -> String {
        let background = "纯白色平面背景（#FFFFFF），无纸张纹理、无画框、无地毯、无阴影、无道具，狗狗全身居中，四肢完整，仅保留狗狗主体，适合透明抠图"
        let identity = "必须一眼能认出是照片里那只狗：品种、体型、脸型、耳朵、五官、毛色和花纹全部保留，不能换成另一只通用卡通狗"
        let poseLine: String
        switch pose {
        case .sit:
            poseLine = "全身坐姿居中，能看清脸，臀部着地，前肢可见，表情放松"
        case .runA, .runB, .runC, .runD, .land:
            poseLine = pose.promptInstruction
        }

        let styleLine = "温暖手绘插画风格，手绘线条与墨水描边，纸本水彩质感，柔和阴影，亲切可爱，高质量"

        return "【姿势必须遵守】\(poseLine)。将图中的狗狗转换为\(styleLine)。\(identity)。再次强调姿势：\(poseLine)。\(background)"
    }

    var negativePrompt: String {
        negativePrompt(for: .sit)
    }

    func negativePrompt(for pose: CompanionPose) -> String {
        var prompt = "模糊，低画质，变形，畸形，丑陋，人体，文字，水印，低分辨率，另一只狗，通用卡通吉祥物，3D渲染，照片写实，背景纹理，纸张质感，画框，地毯，阴影，场景，家具"
        if pose != .sit {
            prompt += "，坐着，坐姿，蹲坐，正面证件照，sitting, seated, lying down, sitting down, front portrait"
        }
        return prompt
    }
}
