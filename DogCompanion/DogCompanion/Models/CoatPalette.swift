import SwiftUI
import UIKit

enum CoatPalette: String, CaseIterable, Identifiable, Equatable {
    case black
    case brown
    case white
    case orange
    case gray
    case spotted

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .black: return "黑色"
        case .brown: return "棕色"
        case .white: return "白色"
        case .orange: return "橘色"
        case .gray: return "灰色"
        case .spotted: return "花斑"
        }
    }

    var hasSpots: Bool { self == .spotted }

    var fill: UIColor {
        switch self {
        case .black:
            return UIColor(red: 0.16, green: 0.14, blue: 0.13, alpha: 1)
        case .brown:
            return UIColor(red: 0.72, green: 0.46, blue: 0.26, alpha: 1)
        case .white:
            return UIColor(red: 0.93, green: 0.90, blue: 0.84, alpha: 1)
        case .orange:
            return UIColor(red: 0.86, green: 0.52, blue: 0.22, alpha: 1)
        case .gray:
            return UIColor(red: 0.62, green: 0.60, blue: 0.58, alpha: 1)
        case .spotted:
            return UIColor(red: 0.90, green: 0.86, blue: 0.78, alpha: 1)
        }
    }

    var belly: UIColor {
        switch self {
        case .black:
            return UIColor(red: 0.32, green: 0.28, blue: 0.24, alpha: 1)
        case .brown:
            return UIColor(red: 0.93, green: 0.84, blue: 0.70, alpha: 1)
        case .white:
            return UIColor(red: 0.99, green: 0.97, blue: 0.93, alpha: 1)
        case .orange:
            return UIColor(red: 0.96, green: 0.88, blue: 0.72, alpha: 1)
        case .gray:
            return UIColor(red: 0.82, green: 0.80, blue: 0.78, alpha: 1)
        case .spotted:
            return UIColor(red: 0.98, green: 0.95, blue: 0.90, alpha: 1)
        }
    }

    var spot: UIColor {
        switch self {
        case .spotted:
            return UIColor(red: 0.22, green: 0.18, blue: 0.16, alpha: 1)
        default:
            return fill
        }
    }

    var swatch: Color { Color(fill) }
}
