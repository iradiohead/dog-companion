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
        switch self {
        case .anime:
            return "cute dog, anime illustration, soft lines, expressive eyes, vibrant colors, high quality, detailed fur"
        case .flatCartoon:
            return "cute dog, flat vector cartoon, clean shapes, modern app illustration, bold colors, simple background"
        case .watercolor:
            return "cute dog, watercolor painting, warm tones, hand-painted texture, artistic, soft edges"
        }
    }

    var negativePrompt: String {
        "blurry, low quality, distorted, deformed, ugly, bad anatomy, human, text, watermark"
    }
}
