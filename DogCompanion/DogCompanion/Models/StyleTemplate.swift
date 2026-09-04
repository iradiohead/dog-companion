import Foundation
import SwiftData

enum StyleTemplate: String, CaseIterable, Identifiable, Codable {
    case anime
    case flatCartoon
    case watercolor

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .anime: return "圆润纸片"
        case .flatCartoon: return "几何剪纸"
        case .watercolor: return "蜡笔纸片"
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
        let background = "纯白色平面背景（#FFFFFF），无家具、无地毯、无阴影、无文字、无画框，狗狗全身居中"
        let poseLine: String
        switch pose {
        case .sit:
            poseLine = "全身坐姿，3/4偏侧面，面朝右上，能看到背部和一侧脸，尾巴在身体左侧，前肢收在身前"
        case .runA, .runB, .runC, .runD, .land:
            poseLine = pose.promptInstruction
        }

        let paperBase = "剪纸拼贴纸片风，蜡笔深色勾边，边缘毛糙像剪刀剪出来，扁平色块填充，不是3D、不是写实照片、不是日系大眼精修漫画"
        let styleLine: String
        switch self {
        case .anime:
            styleLine = "\(paperBase)，圆耳朵圆身体，五官极简"
        case .flatCartoon:
            styleLine = "\(paperBase)，更几何的色块，造型更硬朗"
        case .watercolor:
            styleLine = "\(paperBase)，蜡笔涂色有轻微颗粒，颜色更柔"
        }

        let identity = "保留照片中狗狗的毛色和花纹，身体用共用的圆滚纸片狗比例，不要按真实品种解剖去拉长或压扁"

        return "【姿势必须遵守】\(poseLine)。将图中的狗狗转换为\(styleLine)。\(identity)。再次强调姿势：\(poseLine)。\(background)"
    }

    var negativePrompt: String {
        negativePrompt(for: .sit)
    }

    func negativePrompt(for pose: CompanionPose) -> String {
        var prompt = "写实照片，3D渲染，日系大眼精修，光滑矢量logo，模糊，低画质，人体，文字，水印，家具，椅子，地毯，复杂背景"
        if pose != .sit {
            prompt += "，坐着，坐姿，蹲坐，正面证件照，sitting, seated, lying down, sitting down, front portrait"
        }
        return prompt
    }
}
