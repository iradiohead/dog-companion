import SwiftUI

struct WoodenFloorView: View {
    let floorColor: Color
    let plankColor: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                floorColor

                VStack(spacing: 0) {
                    ForEach(0..<6, id: \.self) { index in
                        Rectangle()
                            .fill(plankColor.opacity(0.08 + Double(index % 2) * 0.04))
                            .frame(height: geo.size.height / 6)
                            .overlay(alignment: .top) {
                                Path { path in
                                    path.move(to: .zero)
                                    path.addLine(to: CGPoint(x: geo.size.width, y: 0))
                                }
                                .stroke(HandDrawnPalette.ink.opacity(0.12), lineWidth: 1.5)
                            }
                    }
                }
            }
        }
    }
}

struct WallPaintingView: View {
    let accent: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(HandDrawnPalette.cream)
                .frame(width: 110, height: 82)
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(HandDrawnPalette.ink.opacity(0.45), lineWidth: 3)
                }

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(accent.opacity(0.25))
                .frame(width: 92, height: 64)
                .overlay {
                    VStack(spacing: 6) {
                        Circle()
                            .fill(HandDrawnPalette.warmGlow.opacity(0.8))
                            .frame(width: 18, height: 18)
                            .offset(x: 20, y: -8)
                        Path { path in
                            path.move(to: CGPoint(x: 10, y: 50))
                            path.addQuadCurve(
                                to: CGPoint(x: 82, y: 50),
                                control: CGPoint(x: 46, y: 28)
                            )
                            path.addLine(to: CGPoint(x: 82, y: 58))
                            path.addLine(to: CGPoint(x: 10, y: 58))
                            path.closeSubpath()
                        }
                        .fill(Color(red: 0.45, green: 0.62, blue: 0.42).opacity(0.7))
                    }
                    .frame(width: 92, height: 64)
                }
        }
        .shadow(color: HandDrawnPalette.ink.opacity(0.1), radius: 4, y: 2)
    }
}

struct FloorLampView: View {
    let isLit: Bool
    let accent: Color

    var body: some View {
        ZStack(alignment: .bottom) {
            if isLit {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                HandDrawnPalette.warmGlow.opacity(0.55),
                                HandDrawnPalette.warmGlow.opacity(0.15),
                                .clear
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .offset(x: 30, y: -80)
                    .blur(radius: 8)
            }

            VStack(spacing: 0) {
                ZStack {
                    Path { path in
                        path.move(to: CGPoint(x: 18, y: 0))
                        path.addQuadCurve(to: CGPoint(x: 62, y: 0), control: CGPoint(x: 40, y: -8))
                        path.addLine(to: CGPoint(x: 58, y: 28))
                        path.addQuadCurve(to: CGPoint(x: 22, y: 28), control: CGPoint(x: 40, y: 36))
                        path.closeSubpath()
                    }
                    .fill(accent.opacity(0.85))
                    .overlay {
                        Path { path in
                            path.move(to: CGPoint(x: 18, y: 0))
                            path.addQuadCurve(to: CGPoint(x: 62, y: 0), control: CGPoint(x: 40, y: -8))
                            path.addLine(to: CGPoint(x: 58, y: 28))
                            path.addQuadCurve(to: CGPoint(x: 22, y: 28), control: CGPoint(x: 40, y: 36))
                            path.closeSubpath()
                        }
                        .stroke(HandDrawnPalette.ink.opacity(0.5), lineWidth: 2)
                    }

                    if isLit {
                        Circle()
                            .fill(HandDrawnPalette.warmGlow)
                            .frame(width: 10, height: 10)
                            .offset(y: 10)
                            .blur(radius: 2)
                    }
                }
                .frame(width: 80, height: 32)

                Rectangle()
                    .fill(HandDrawnPalette.inkLight.opacity(0.55))
                    .frame(width: 5, height: 130)
                    .overlay {
                        Rectangle()
                            .strokeBorder(HandDrawnPalette.ink.opacity(0.35), lineWidth: 1)
                    }

                Ellipse()
                    .fill(HandDrawnPalette.ink.opacity(0.2))
                    .frame(width: 48, height: 14)
            }
        }
        .frame(width: 100, height: 180)
    }
}

struct SideTableView: View {
    let topColor: Color

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(topColor)
                .frame(width: 100, height: 14)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(HandDrawnPalette.ink.opacity(0.4), lineWidth: 2)
                }

            HStack(spacing: 28) {
                Rectangle()
                    .fill(HandDrawnPalette.inkLight.opacity(0.5))
                    .frame(width: 5, height: 52)
                Rectangle()
                    .fill(HandDrawnPalette.inkLight.opacity(0.5))
                    .frame(width: 5, height: 52)
            }
            .overlay {
                HStack(spacing: 28) {
                    Rectangle().strokeBorder(HandDrawnPalette.ink.opacity(0.3), lineWidth: 1).frame(width: 5, height: 52)
                    Rectangle().strokeBorder(HandDrawnPalette.ink.opacity(0.3), lineWidth: 1).frame(width: 5, height: 52)
                }
            }
        }
        .shadow(color: HandDrawnPalette.ink.opacity(0.12), radius: 4, y: 3)
    }
}

struct DogMatView: View {
    let color: Color

    var body: some View {
        Ellipse()
            .fill(color)
            .frame(width: 150, height: 42)
            .overlay {
                Ellipse()
                    .strokeBorder(HandDrawnPalette.ink.opacity(0.25), lineWidth: 2)
            }
            .shadow(color: HandDrawnPalette.ink.opacity(0.1), radius: 3, y: 2)
    }
}
