import SwiftUI

enum HandDrawnPalette {
    static let ink = Color(red: 0.28, green: 0.22, blue: 0.18)
    static let inkLight = Color(red: 0.45, green: 0.38, blue: 0.32)
    static let paper = Color(red: 0.98, green: 0.95, blue: 0.90)
    static let cream = Color(red: 0.96, green: 0.91, blue: 0.84)
    static let warmGlow = Color(red: 1.0, green: 0.88, blue: 0.55)
}

struct SketchStroke: ShapeStyle {
    func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        HandDrawnPalette.ink.opacity(0.85)
    }
}

struct HandDrawnStroke: ViewModifier {
    var lineWidth: CGFloat = 2.5

    func body(content: Content) -> some View {
        content
            .overlay {
                content
                    .blur(radius: 0.3)
                    .opacity(0.4)
                    .offset(x: 0.6, y: 0.6)
            }
    }
}

struct HandDrawnCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(HandDrawnPalette.paper.opacity(0.92))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(HandDrawnPalette.ink.opacity(0.35), lineWidth: 2)
                    }
                    .shadow(color: HandDrawnPalette.ink.opacity(0.08), radius: 8, y: 4)
            }
    }
}

struct HandDrawnIconButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(label)
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(HandDrawnPalette.ink)
            .frame(width: 56, height: 52)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(HandDrawnPalette.paper.opacity(0.88))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(HandDrawnPalette.ink.opacity(0.3), lineWidth: 1.8)
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

struct HandDrawnActionButton: View {
    let title: String
    let icon: String?
    var tint: Color = Color(red: 0.82, green: 0.55, blue: 0.38)
    var isPrimary: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.headline)
                }
                Text(title)
                    .font(.headline.weight(.semibold))
            }
            .foregroundStyle(isPrimary ? HandDrawnPalette.paper : HandDrawnPalette.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                Capsule(style: .continuous)
                    .fill(isPrimary ? tint : HandDrawnPalette.cream)
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(HandDrawnPalette.ink.opacity(isPrimary ? 0.2 : 0.35), lineWidth: 2)
                    }
            }
        }
        .buttonStyle(.plain)
    }
}
