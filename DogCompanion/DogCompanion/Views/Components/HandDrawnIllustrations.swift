import SwiftUI

struct WoodenFloorView: View {
    let floorColor: Color
    let plankColor: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [floorColor.opacity(0.5), floorColor.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { index in
                        let plankHeight = geo.size.height / 7
                        ZStack {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            plankColor.opacity(0.06 + Double(index % 3) * 0.03),
                                            plankColor.opacity(0.14 + Double(index % 2) * 0.04)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Canvas { context, size in
                                let grainCount = 4
                                for grain in 0..<grainCount {
                                    let y = CGFloat(grain + 1) * size.height / CGFloat(grainCount + 1)
                                    var path = Path()
                                    path.move(to: CGPoint(x: 0, y: y))
                                    path.addQuadCurve(
                                        to: CGPoint(x: size.width, y: y + 1.5),
                                        control: CGPoint(x: size.width * 0.5, y: y - 1)
                                    )
                                    context.stroke(
                                        path,
                                        with: .color(HandDrawnPalette.ink.opacity(0.06)),
                                        lineWidth: 0.8
                                    )
                                }
                            }

                            if index % 3 == 1 {
                                Ellipse()
                                    .fill(HandDrawnPalette.ink.opacity(0.04))
                                    .frame(width: 18, height: 8)
                                    .offset(x: CGFloat(index * 17) - 20)
                            }
                        }
                        .frame(height: plankHeight)
                        .overlay(alignment: .top) {
                            Rectangle()
                                .fill(HandDrawnPalette.ink.opacity(0.1))
                                .frame(height: 1.2)
                        }
                    }
                }

                LinearGradient(
                    colors: [.black.opacity(0.06), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 10)

                PaperGrainOverlay(opacity: 0.35)
            }
        }
    }
}

struct WallPaintingView: View {
    let accent: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            HandDrawnPalette.wood.opacity(0.95),
                            HandDrawnPalette.wood.opacity(0.75)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 118, height: 90)
                .overlay {
                    HandDrawnSketchStroke(inset: 2, wobble: 2)
                        .stroke(HandDrawnPalette.ink.opacity(0.45), lineWidth: 2.5)
                }

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(HandDrawnPalette.cream)
                .frame(width: 98, height: 72)
                .paperTextured(opacity: 0.4)
                .overlay {
                    ZStack {
                        accent.opacity(0.18)
                            .blur(radius: 6)

                        VStack(spacing: 6) {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            HandDrawnPalette.warmGlow,
                                            HandDrawnPalette.warmGlow.opacity(0.4)
                                        ],
                                        center: .center,
                                        startRadius: 2,
                                        endRadius: 12
                                    )
                                )
                                .frame(width: 20, height: 20)
                                .offset(x: 22, y: -10)

                            Path { path in
                                path.move(to: CGPoint(x: 10, y: 50))
                                path.addQuadCurve(
                                    to: CGPoint(x: 82, y: 50),
                                    control: CGPoint(x: 46, y: 26)
                                )
                                path.addLine(to: CGPoint(x: 82, y: 58))
                                path.addLine(to: CGPoint(x: 10, y: 58))
                                path.closeSubpath()
                            }
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.42, green: 0.62, blue: 0.40),
                                        Color(red: 0.52, green: 0.72, blue: 0.48)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay {
                                Path { path in
                                    path.move(to: CGPoint(x: 10, y: 50))
                                    path.addQuadCurve(
                                        to: CGPoint(x: 82, y: 50),
                                        control: CGPoint(x: 46, y: 26)
                                    )
                                }
                                .stroke(HandDrawnPalette.ink.opacity(0.2), lineWidth: 1)
                            }
                        }
                        .frame(width: 92, height: 64)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .strokeBorder(HandDrawnPalette.ink.opacity(0.25), lineWidth: 1)
                }
        }
        .handDrawnShadow(radius: 5, y: 3)
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
                                HandDrawnPalette.warmGlow.opacity(0.62),
                                HandDrawnPalette.warmGlow.opacity(0.18),
                                .clear
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)
                    .offset(x: 30, y: -90)
                    .blur(radius: 10)
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
                    .fill(
                        LinearGradient(
                            colors: [accent, accent.opacity(0.72), accent.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
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
                    .paperTextured(opacity: 0.25)

                    if isLit {
                        Circle()
                            .fill(HandDrawnPalette.warmGlow)
                            .frame(width: 12, height: 12)
                            .offset(y: 10)
                            .blur(radius: 3)
                    }
                }
                .frame(width: 80, height: 32)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                HandDrawnPalette.inkLight.opacity(0.7),
                                HandDrawnPalette.ink.opacity(0.35),
                                HandDrawnPalette.inkLight.opacity(0.55)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 5, height: 130)
                    .overlay {
                        Rectangle()
                            .strokeBorder(HandDrawnPalette.ink.opacity(0.35), lineWidth: 1)
                    }

                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                HandDrawnPalette.ink.opacity(0.22),
                                HandDrawnPalette.ink.opacity(0.08)
                            ],
                            center: .center,
                            startRadius: 2,
                            endRadius: 28
                        )
                    )
                    .frame(width: 52, height: 14)
            }
        }
        .frame(width: 100, height: 180)
        .handDrawnShadow()
    }
}

struct SideTableView: View {
    let topColor: Color

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .watercolorFill(topColor)
                .frame(width: 100, height: 14)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(HandDrawnPalette.ink.opacity(0.4), lineWidth: 2)
                }
                .paperTextured(opacity: 0.2)

            HStack(spacing: 28) {
                tableLeg
                tableLeg
            }
        }
        .handDrawnShadow()
    }

    private var tableLeg: some View {
        Rectangle()
            .fill(HandDrawnPalette.inkLight.opacity(0.5))
            .frame(width: 5, height: 52)
            .overlay {
                Rectangle()
                    .strokeBorder(HandDrawnPalette.ink.opacity(0.3), lineWidth: 1)
            }
    }
}

/// Focus companion desk — dog sits on the floor beside it.
struct StudyDeskView: View {
    let topColor: Color

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .watercolorFill(topColor, highlight: HandDrawnPalette.cream)
                        .frame(width: 136, height: 14)
                        .overlay {
                            Canvas { context, size in
                                for index in 0..<5 {
                                    let y = CGFloat(index + 1) * size.height / 6
                                    var path = Path()
                                    path.move(to: CGPoint(x: 4, y: y))
                                    path.addLine(to: CGPoint(x: size.width - 4, y: y + 0.5))
                                    context.stroke(
                                        path,
                                        with: .color(HandDrawnPalette.ink.opacity(0.08)),
                                        lineWidth: 0.7
                                    )
                                }
                            }
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(HandDrawnPalette.ink.opacity(0.42), lineWidth: 2)
                        }
                        .paperTextured(opacity: 0.22)

                    deskLamp
                        .offset(x: 14, y: -18)

                    openNotebook
                        .offset(x: 78, y: -20)
                }
                .frame(height: 14)

                HStack(spacing: 100) {
                    deskLeg
                    deskLeg
                }
            }

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            HandDrawnPalette.ink.opacity(0.14),
                            HandDrawnPalette.ink.opacity(0.04)
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: 60
                    )
                )
                .frame(width: 130, height: 12)
                .offset(y: 5)
        }
        .frame(width: 148, height: 82)
        .handDrawnShadow(radius: 7, y: 4)
    }

    private var deskLamp: some View {
        ZStack(alignment: .bottom) {
            Path { path in
                path.move(to: CGPoint(x: 4, y: 0))
                path.addQuadCurve(to: CGPoint(x: 20, y: 0), control: CGPoint(x: 12, y: -3))
                path.addLine(to: CGPoint(x: 18, y: 10))
                path.addQuadCurve(to: CGPoint(x: 6, y: 10), control: CGPoint(x: 12, y: 13))
                path.closeSubpath()
            }
            .fill(Color(red: 0.94, green: 0.62, blue: 0.38).opacity(0.9))
            .overlay {
                Path { path in
                    path.move(to: CGPoint(x: 4, y: 0))
                    path.addQuadCurve(to: CGPoint(x: 20, y: 0), control: CGPoint(x: 12, y: -3))
                    path.addLine(to: CGPoint(x: 18, y: 10))
                    path.addQuadCurve(to: CGPoint(x: 6, y: 10), control: CGPoint(x: 12, y: 13))
                    path.closeSubpath()
                }
                .stroke(HandDrawnPalette.ink.opacity(0.3), lineWidth: 1)
            }

            Rectangle()
                .fill(HandDrawnPalette.inkLight.opacity(0.5))
                .frame(width: 2, height: 8)
        }
        .frame(width: 24, height: 18)
    }

    private var openNotebook: some View {
        HStack(spacing: 1) {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(HandDrawnPalette.cream)
                .frame(width: 14, height: 20)
                .overlay {
                    VStack(spacing: 3) {
                        ForEach(0..<4, id: \.self) { _ in
                            Rectangle()
                                .fill(HandDrawnPalette.ink.opacity(0.1))
                                .frame(height: 0.8)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(Color(red: 0.55, green: 0.72, blue: 0.88).opacity(0.55))
                .frame(width: 14, height: 20)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .strokeBorder(HandDrawnPalette.ink.opacity(0.32), lineWidth: 1)
        }
        .paperTextured(opacity: 0.18)
    }

    private var deskLeg: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        HandDrawnPalette.inkLight.opacity(0.55),
                        HandDrawnPalette.ink.opacity(0.28)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 6, height: 58)
            .overlay {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .strokeBorder(HandDrawnPalette.ink.opacity(0.3), lineWidth: 1)
            }
    }
}

struct DogMatView: View {
    let color: Color

    var body: some View {
        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            color.opacity(0.95),
                            color.opacity(0.78),
                            color.opacity(0.88)
                        ],
                        center: UnitPoint(x: 0.4, y: 0.35),
                        startRadius: 10,
                        endRadius: 120
                    )
                )
                .frame(width: 228, height: 62)

            Canvas { context, size in
                for row in 0..<5 {
                    for column in 0..<9 {
                        let x = CGFloat(column) * size.width / 8
                        let y = CGFloat(row) * size.height / 4
                        let rect = CGRect(x: x - 4, y: y - 2, width: 8, height: 4)
                        context.stroke(
                            Path(ellipseIn: rect),
                            with: .color(HandDrawnPalette.ink.opacity(0.06)),
                            lineWidth: 0.6
                        )
                    }
                }
            }
            .frame(width: 228, height: 62)

            Ellipse()
                .strokeBorder(
                    HandDrawnPalette.ink.opacity(0.22),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 3])
                )
                .frame(width: 228, height: 62)
        }
        .handDrawnShadow(radius: 4, y: 2)
    }
}

struct ArmChairView: View {
    let seatColor: Color

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .watercolorFill(seatColor)
                        .frame(width: 150, height: 88)
                        .overlay {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .strokeBorder(HandDrawnPalette.ink.opacity(0.35), lineWidth: 2.5)
                        }
                        .paperTextured(opacity: 0.2)

                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(seatColor.opacity(0.95))
                        .frame(width: 34, height: 70)
                        .offset(x: -18, y: -8)
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(HandDrawnPalette.ink.opacity(0.3), lineWidth: 2)
                        }

                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .watercolorFill(HandDrawnPalette.wood)
                        .frame(width: 42, height: 12)
                        .offset(x: -36, y: 24)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(HandDrawnPalette.ink.opacity(0.25), lineWidth: 1.5)
                        }
                }

                HStack(spacing: 52) {
                    leg
                    leg
                    leg
                }
                .offset(y: -2)
            }
        }
        .frame(width: 170, height: 120)
        .handDrawnShadow()
    }

    private var leg: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .watercolorFill(HandDrawnPalette.wood)
            .frame(width: 8, height: 28)
            .overlay {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .strokeBorder(HandDrawnPalette.ink.opacity(0.25), lineWidth: 1)
            }
    }
}

struct GiftBasketView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Path { path in
                path.move(to: CGPoint(x: 10, y: 20))
                path.addQuadCurve(to: CGPoint(x: 70, y: 20), control: CGPoint(x: 40, y: 42))
                path.addLine(to: CGPoint(x: 66, y: 52))
                path.addQuadCurve(to: CGPoint(x: 14, y: 52), control: CGPoint(x: 40, y: 58))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.42, green: 0.66, blue: 0.70).opacity(0.85),
                        Color(red: 0.48, green: 0.72, blue: 0.76).opacity(0.7)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                Path { path in
                    path.move(to: CGPoint(x: 10, y: 20))
                    path.addQuadCurve(to: CGPoint(x: 70, y: 20), control: CGPoint(x: 40, y: 42))
                    path.addLine(to: CGPoint(x: 66, y: 52))
                    path.addQuadCurve(to: CGPoint(x: 14, y: 52), control: CGPoint(x: 40, y: 58))
                    path.closeSubpath()
                }
                .stroke(HandDrawnPalette.ink.opacity(0.35), lineWidth: 2)
            }
            .paperTextured(opacity: 0.2)

            HStack(spacing: 4) {
                Circle().fill(Color.pink.opacity(0.75)).frame(width: 10, height: 10)
                Circle().fill(Color.orange.opacity(0.75)).frame(width: 8, height: 8)
                Circle().fill(Color.green.opacity(0.65)).frame(width: 9, height: 9)
            }
            .offset(y: -8)
        }
        .frame(width: 80, height: 56)
        .handDrawnShadow(radius: 4, y: 2)
    }
}

struct CornerDoodlesView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "pawprint.fill")
            Image(systemName: "leaf.fill")
        }
        .font(.caption)
        .foregroundStyle(HandDrawnPalette.ink.opacity(0.32))
    }
}
