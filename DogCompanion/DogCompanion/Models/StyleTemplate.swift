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
        let backgroundConstraint = "纯色米白背景，无道具无阴影，狗狗全身坐姿居中，四肢完整，适合抠图"
        switch self {
        case .anime:
            return "将照片中的狗狗转换为可爱的日系动漫插画风格，保留毛色、花纹和品种特征，线条柔和，眼睛有神，色彩鲜明，高质量，\(backgroundConstraint)"
        case .flatCartoon:
            return "将照片中的狗狗转换为扁平卡通插画风格，保留毛色和品种特征，简洁造型，现代应用插画感，色彩明快，\(backgroundConstraint)"
        case .watercolor:
            return "将照片中的狗狗转换为水彩手绘风格，保留毛色和品种特征，温暖色调，手绘质感，艺术感，柔和边缘，\(backgroundConstraint)"
        }
    }

    var negativePrompt: String {
        "模糊，低画质，变形，畸形，丑陋，人体，文字，水印，低分辨率，手指畸形，AI感过重"
    }
}
