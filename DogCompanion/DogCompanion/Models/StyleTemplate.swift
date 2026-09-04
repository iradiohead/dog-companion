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

    var shortDescription: String {
        switch self {
        case .anime: return "日系插画，保留照片里那只"
        case .flatCartoon: return "扁平插画，品种花纹不改"
        case .watercolor: return "水彩手绘，还是你的狗"
        }
    }

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

        let styleLine: String
        switch self {
        case .anime:
            styleLine = "可爱的日系动漫插画风格，线条柔和，眼睛有神，色彩鲜明，高质量"
        case .flatCartoon:
            styleLine = "扁平卡通插画风格，简洁造型，现代应用插画感，色彩明快"
        case .watercolor:
            styleLine = "水彩手绘风格，温暖色调，手绘质感，艺术感"
        }

        return "【姿势必须遵守】\(poseLine)。将图中的狗狗转换为\(styleLine)。\(identity)。再次强调姿势：\(poseLine)。\(background)"
    }

    var negativePrompt: String {
        negativePrompt(for: .sit)
    }

    func negativePrompt(for pose: CompanionPose) -> String {
        var prompt = "模糊，低画质，变形，畸形，丑陋，人体，文字，水印，低分辨率，另一只狗，通用卡通吉祥物，背景纹理，纸张质感，画框，地毯，阴影，场景，家具"
        if pose != .sit {
            prompt += "，坐着，坐姿，蹲坐，正面证件照，sitting, seated, lying down, sitting down, front portrait"
        }
        return prompt
    }
}
