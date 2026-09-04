import Foundation
import SwiftData

enum StyleTemplate: String, CaseIterable, Identifiable, Codable {
    case anime
    case flatCartoon
    case watercolor

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .anime: return "日系动漫"
        case .flatCartoon: return "扁平卡通"
        case .watercolor: return "水彩手绘"
        }
    }

    var iconName: String {
        switch self {
        case .anime: return "sparkles"
        case .flatCartoon: return "square.on.circle"
        case .watercolor: return "paintbrush.pointed"
        }
    }

    var prompt: String {
        prompt(for: .sit)
    }

    func prompt(for pose: CompanionPose) -> String {
        let background = "纯白色平面背景（#FFFFFF），无纸张纹理、无画框、无地毯、无阴影、无道具，狗狗全身居中，四肢完整，仅保留狗狗主体，适合透明抠图"
        let identity: String
        switch pose {
        case .sit:
            identity = "保留照片中狗狗的毛色、花纹和品种特征"
        case .runA, .runB, .runC, .runD, .land:
            identity = "必须与参考图是同一只狗：品种、毛色、花纹、耳朵、五官和画风完全一致。只改姿势，不要复制参考图里的坐姿"
        }

        let styleLine: String
        switch self {
        case .anime:
            styleLine = "可爱的日系动漫插画风格，线条柔和，眼睛有神，色彩鲜明，高质量"
        case .flatCartoon:
            styleLine = "扁平卡通插画风格，简洁造型，现代应用插画感，色彩明快"
        case .watercolor:
            styleLine = "水彩手绘风格，温暖色调，手绘质感，艺术感"
        }

        return "【姿势必须遵守】\(pose.promptInstruction)。将图中的狗狗转换为\(styleLine)。\(identity)。再次强调姿势：\(pose.promptInstruction)。\(background)"
    }

    var negativePrompt: String {
        negativePrompt(for: .sit)
    }

    func negativePrompt(for pose: CompanionPose) -> String {
        var prompt = "模糊，低画质，变形，畸形，丑陋，人体，文字，水印，低分辨率，手指畸形，AI感过重，背景纹理，纸张质感，画框，地毯，阴影，场景，家具"
        if pose != .sit {
            prompt += "，坐着，坐姿，蹲坐，正面证件照，sitting, seated, lying down, sitting down, front portrait"
        }
        return prompt
    }
}
