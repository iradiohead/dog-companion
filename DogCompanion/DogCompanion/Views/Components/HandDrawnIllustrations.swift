import SwiftUI

struct WoodenFloorView: View {
    let floorColor: Color
    let plankColor: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [
                        floorColor.opacity(0.18),
                        floorColor.opacity(0.55),
                        floorColor.darker(by: 0.08).opacity(0.7)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                WatercolorWashOverlay(colors: [
                    floorColor,
                    HandDrawnPalette.wood.opacity(0.55),
                    plankColor.opacity(0.25)
                ])

                Canvas { context, size in
                    for index in 0..<5 {
                        let y = size.height * (0.18 + CGFloat(index) * 0.16)
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addQuadCurve(
                            to: CGPoint(x: size.width, y: y + 2),
                            control: CGPoint(x: size.width * 0.5, y: y - 3 + CGFloat(index))
                        )
                        context.stroke(
                            path,
                            with: .color(HandDrawnPalette.ink.opacity(0.05 + Double(index) * 0.01)),
                            lineWidth: 1.1
                        )
                    }
                }

                PencilHatchOverlay(
                    color: plankColor,
                    opacity: 0.07,
                    density: 14,
                    angle: 2
                )

                LinearGradient(
                    colors: [HandDrawnPalette.ink.opacity(0.08), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 18)

                PaperFiberOverlay(opacity: 0.32, seed: 5)
            }
        }
    }
}

struct WallPaintingView: View {
    let accent: Color

    var body: some View {
        ZStack {
            WobblyRoundedRectangle(cornerRadius: 5, wobble: 2.4, seed: 2)
                .fill(HandDrawnPalette.wood)
                .overlay {
                    WatercolorPigment(
                        color: HandDrawnPalette.wood,
                        highlight: HandDrawnPalette.cream
                    )
                    .clipShape(WobblyRoundedRectangle(cornerRadius: 5, wobble: 2.4, seed: 2))
                }
                .overlay {
                    ZStack {
                        WobblyRoundedRectangle(cornerRadius: 5, wobble: 2.6, seed: 3)
                            .stroke(HandDrawnPalette.ink.opacity(0.28), lineWidth: 3.2)
                            .offset(x: 0.6, y: 0.8)
                        WobblyRoundedRectangle(cornerRadius: 5, wobble: 2.2, seed: 4)
                            .stroke(HandDrawnPalette.ink.opacity(0.5), lineWidth: 1.8)
                    }
                }
                .frame(width: 122, height: 94)

            WobblyRoundedRectangle(cornerRadius: 3, wobble: 1.6, seed: 6)
                .fill(HandDrawnPalette.cream)
                .overlay {
                    WatercolorPigment(color: HandDrawnPalette.cream, highlight: .white)
                        .clipShape(WobblyRoundedRectangle(cornerRadius: 3, wobble: 1.6, seed: 6))
                }
                .overlay {
                    Canvas { context, size in
                        var hill = Path()
                        hill.move(to: CGPoint(x: 8, y: size.height * 0.72))
                        hill.addQuadCurve(
                            to: CGPoint(x: size.width - 8, y: size.height * 0.7),
                            control: CGPoint(x: size.width * 0.5, y: size.height * 0.38)
                        )
                        hill.addLine(to: CGPoint(x: size.width - 8, y: size.height - 8))
                        hill.addLine(to: CGPoint(x: 8, y: size.height - 8))
                        hill.closeSubpath()
                        context.fill(hill, with: .color(accent.opacity(0.55)))
                        context.stroke(hill, with: .color(HandDrawnPalette.ink.opacity(0.18)), lineWidth: 1)

                        let sun = Path(ellipseIn: CGRect(x: size.width * 0.58, y: size.height * 0.16, width: 16, height: 15))
                        context.fill(sun, with: .color(HandDrawnPalette.warmGlow.opacity(0.9)))
                    }
                    PencilHatchOverlay(opacity: 0.08, density: 10, angle: -18)
                }
                .overlay {
                    WobblyRoundedRectangle(cornerRadius: 3, wobble: 1.8, seed: 7)
                        .stroke(HandDrawnPalette.ink.opacity(0.32), lineWidth: 1.2)
                }
                .frame(width: 98, height: 72)
        }
        .handDrawnShadow(radius: 6, y: 4)
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
                                HandDrawnPalette.warmGlow.opacity(0.12),
                                .clear
                            ],
                            center: .center,
                            startRadius: 6,
                            endRadius: 130
                        )
                    )
                    .frame(width: 260, height: 260)
                    .offset(x: 28, y: -86)
                    .blur(radius: 12)
            }

            VStack(spacing: 0) {
                lampShade
                    .frame(width: 84, height: 36)

                Canvas { context, size in
                    var pole = Path()
                    pole.move(to: CGPoint(x: size.width * 0.5 + 1, y: 0))
                    pole.addQuadCurve(
                        to: CGPoint(x: size.width * 0.5 - 1, y: size.height),
                        control: CGPoint(x: size.width * 0.5 + 3, y: size.height * 0.45)
                    )
                    context.stroke(pole, with: .color(HandDrawnPalette.ink.opacity(0.22)), lineWidth: 5.5)
                    context.stroke(pole, with: .color(HandDrawnPalette.inkLight.opacity(0.7)), lineWidth: 2.4)
                }
                .frame(width: 18, height: 128)

                WobblyEllipse(wobble: 1.2, seed: 12)
                    .fill(HandDrawnPalette.ink.opacity(0.16))
                    .frame(width: 54, height: 13)
            }
        }
        .frame(width: 100, height: 180)
        .handDrawnShadow(radius: 5, y: 3)
    }

    private var lampShade: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 16, y: 4))
                path.addQuadCurve(to: CGPoint(x: 68, y: 3), control: CGPoint(x: 42, y: -6))
                path.addLine(to: CGPoint(x: 62, y: 30))
                path.addQuadCurve(to: CGPoint(x: 20, y: 31), control: CGPoint(x: 42, y: 38))
                path.closeSubpath()
            }
            .fill(accent)
            .overlay {
                WatercolorPigment(color: accent, highlight: HandDrawnPalette.warmGlow)
                    .clipShape(
                        Path { path in
                            path.move(to: CGPoint(x: 16, y: 4))
                            path.addQuadCurve(to: CGPoint(x: 68, y: 3), control: CGPoint(x: 42, y: -6))
                            path.addLine(to: CGPoint(x: 62, y: 30))
                            path.addQuadCurve(to: CGPoint(x: 20, y: 31), control: CGPoint(x: 42, y: 38))
                            path.closeSubpath()
                        }
                    )
            }
            .overlay {
                Path { path in
                    path.move(to: CGPoint(x: 16, y: 4))
                    path.addQuadCurve(to: CGPoint(x: 68, y: 3), control: CGPoint(x: 42, y: -6))
                    path.addLine(to: CGPoint(x: 62, y: 30))
                    path.addQuadCurve(to: CGPoint(x: 20, y: 31), control: CGPoint(x: 42, y: 38))
                    path.closeSubpath()
                }
                .stroke(HandDrawnPalette.ink.opacity(0.42), lineWidth: 1.8)
            }

            if isLit {
                Circle()
                    .fill(HandDrawnPalette.warmGlow)
                    .frame(width: 11, height: 11)
                    .offset(y: 8)
                    .blur(radius: 2.5)
            }
        }
    }
}

struct SideTableView: View {
    let topColor: Color

    var body: some View {
        VStack(spacing: 0) {
            WobblyRoundedRectangle(cornerRadius: 8, wobble: 1.6, seed: 14)
                .fill(topColor)
                .overlay {
                    WatercolorPigment(color: topColor, highlight: HandDrawnPalette.cream)
                        .clipShape(WobblyRoundedRectangle(cornerRadius: 8, wobble: 1.6, seed: 14))
                }
                .overlay {
                    WobblyRoundedRectangle(cornerRadius: 8, wobble: 1.8, seed: 15)
                        .stroke(HandDrawnPalette.ink.opacity(0.4), lineWidth: 1.8)
                }
                .frame(width: 100, height: 14)

            HStack(spacing: 28) {
                tableLeg
                tableLeg
            }
        }
        .handDrawnShadow()
    }

    private var tableLeg: some View {
        Capsule(style: .continuous)
            .fill(HandDrawnPalette.inkLight.opacity(0.5))
            .frame(width: 5, height: 52)
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(HandDrawnPalette.ink.opacity(0.28), lineWidth: 1)
            }
    }
}

struct StudyDeskView: View {
    let topColor: Color

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    WobblyRoundedRectangle(cornerRadius: 7, wobble: 1.8, seed: 20)
                        .fill(topColor)
                        .overlay {
                            WatercolorPigment(color: topColor, highlight: HandDrawnPalette.cream)
                                .clipShape(WobblyRoundedRectangle(cornerRadius: 7, wobble: 1.8, seed: 20))
                        }
                        .overlay {
                            PencilHatchOverlay(color: HandDrawnPalette.ink, opacity: 0.08, density: 8, angle: 4)
                                .clipShape(WobblyRoundedRectangle(cornerRadius: 7, wobble: 1.8, seed: 20))
                        }
                        .overlay {
                            ZStack {
                                WobblyRoundedRectangle(cornerRadius: 7, wobble: 2, seed: 21)
                                    .stroke(HandDrawnPalette.ink.opacity(0.28), lineWidth: 3)
                                    .offset(x: 0.4, y: 0.7)
                                WobblyRoundedRectangle(cornerRadius: 7, wobble: 1.6, seed: 22)
                                    .stroke(HandDrawnPalette.ink.opacity(0.48), lineWidth: 1.7)
                            }
                        }
                        .frame(width: 138, height: 16)

                    deskLamp
                        .offset(x: 14, y: -20)

                    openNotebook
                        .offset(x: 78, y: -22)
                }
                .frame(height: 16)

                HStack(spacing: 102) {
                    deskLeg
                    deskLeg
                }
            }

            BlobShadow(width: 128, height: 12)
                .offset(y: 6)
        }
        .frame(width: 148, height: 86)
    }

    private var deskLamp: some View {
        ZStack(alignment: .bottom) {
            Path { path in
                path.move(to: CGPoint(x: 3, y: 1))
                path.addQuadCurve(to: CGPoint(x: 21, y: 0), control: CGPoint(x: 12, y: -4))
                path.addLine(to: CGPoint(x: 19, y: 11))
                path.addQuadCurve(to: CGPoint(x: 5, y: 11), control: CGPoint(x: 12, y: 14))
                path.closeSubpath()
            }
            .fill(Color(red: 0.94, green: 0.62, blue: 0.38))
            .overlay {
                Path { path in
                    path.move(to: CGPoint(x: 3, y: 1))
                    path.addQuadCurve(to: CGPoint(x: 21, y: 0), control: CGPoint(x: 12, y: -4))
                    path.addLine(to: CGPoint(x: 19, y: 11))
                    path.addQuadCurve(to: CGPoint(x: 5, y: 11), control: CGPoint(x: 12, y: 14))
                    path.closeSubpath()
                }
                .stroke(HandDrawnPalette.ink.opacity(0.35), lineWidth: 1.1)
            }

            Capsule()
                .fill(HandDrawnPalette.inkLight.opacity(0.55))
                .frame(width: 2.2, height: 8)
        }
        .frame(width: 24, height: 18)
    }

    private var openNotebook: some View {
        HStack(spacing: 1) {
            WobblyRoundedRectangle(cornerRadius: 1.5, wobble: 0.8, seed: 30)
                .fill(HandDrawnPalette.cream)
                .overlay {
                    VStack(spacing: 3) {
                        ForEach(0..<4, id: \.self) { index in
                            Capsule()
                                .fill(HandDrawnPalette.ink.opacity(0.12))
                                .frame(height: 0.8)
                                .padding(.leading, CGFloat(index % 2) * 2)
                        }
                    }
                    .padding(.horizontal, 3)
                }
                .frame(width: 15, height: 21)

            WobblyRoundedRectangle(cornerRadius: 1.5, wobble: 0.8, seed: 31)
                .fill(Color(red: 0.55, green: 0.72, blue: 0.88).opacity(0.62))
                .frame(width: 15, height: 21)
        }
        .overlay {
            WobblyRoundedRectangle(cornerRadius: 1.5, wobble: 1, seed: 32)
                .stroke(HandDrawnPalette.ink.opacity(0.32), lineWidth: 1)
        }
    }

    private var deskLeg: some View {
        Capsule(style: .continuous)
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
                Capsule(style: .continuous)
                    .strokeBorder(HandDrawnPalette.ink.opacity(0.28), lineWidth: 1)
            }
    }
}

struct DogMatView: View {
    let color: Color

    var body: some View {
        ZStack {
            WobblyEllipse(wobble: 2.4, seed: 40)
                .fill(
                    RadialGradient(
                        colors: [
                            color.lighter(by: 0.08),
                            color,
                            color.darker(by: 0.1)
                        ],
                        center: UnitPoint(x: 0.38, y: 0.32),
                        startRadius: 8,
                        endRadius: 120
                    )
                )
                .overlay {
                    PencilHatchOverlay(color: color.darker(by: 0.3), opacity: 0.14, density: 16, angle: 18)
                        .clipShape(WobblyEllipse(wobble: 2.4, seed: 40))
                }
                .overlay {
                    ZStack {
                        WobblyEllipse(wobble: 2.6, seed: 41)
                            .stroke(HandDrawnPalette.ink.opacity(0.18), lineWidth: 3)
                        WobblyEllipse(wobble: 2.2, seed: 42)
                            .stroke(HandDrawnPalette.ink.opacity(0.32), lineWidth: 1.5)
                    }
                }
                .frame(width: 210, height: 56)
        }
        .handDrawnShadow(radius: 5, y: 3)
    }
}

struct ArmChairView: View {
    let seatColor: Color

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    WobblyRoundedRectangle(cornerRadius: 28, wobble: 2.8, seed: 50)
                        .fill(seatColor)
                        .overlay {
                            WatercolorPigment(color: seatColor, highlight: seatColor.lighter(by: 0.15))
                                .clipShape(WobblyRoundedRectangle(cornerRadius: 28, wobble: 2.8, seed: 50))
                        }
                        .overlay {
                            WobblyRoundedRectangle(cornerRadius: 28, wobble: 2.6, seed: 51)
                                .stroke(HandDrawnPalette.ink.opacity(0.38), lineWidth: 2.2)
                        }
                        .frame(width: 150, height: 88)

                    WobblyRoundedRectangle(cornerRadius: 18, wobble: 2, seed: 52)
                        .fill(seatColor.opacity(0.95))
                        .frame(width: 34, height: 70)
                        .offset(x: -18, y: -8)
                        .overlay {
                            WobblyRoundedRectangle(cornerRadius: 18, wobble: 2, seed: 53)
                                .stroke(HandDrawnPalette.ink.opacity(0.3), lineWidth: 1.8)
                        }

                    WobblyRoundedRectangle(cornerRadius: 10, wobble: 1.4, seed: 54)
                        .fill(HandDrawnPalette.wood)
                        .frame(width: 42, height: 12)
                        .offset(x: -36, y: 24)
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
        Capsule(style: .continuous)
            .fill(HandDrawnPalette.wood)
            .frame(width: 8, height: 28)
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(HandDrawnPalette.ink.opacity(0.25), lineWidth: 1)
            }
    }
}

struct GiftBasketView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Path { path in
                path.move(to: CGPoint(x: 8, y: 18))
                path.addQuadCurve(to: CGPoint(x: 72, y: 17), control: CGPoint(x: 40, y: 40))
                path.addLine(to: CGPoint(x: 66, y: 52))
                path.addQuadCurve(to: CGPoint(x: 14, y: 53), control: CGPoint(x: 40, y: 60))
                path.closeSubpath()
            }
            .fill(Color(red: 0.42, green: 0.66, blue: 0.70))
            .overlay {
                WatercolorPigment(
                    color: Color(red: 0.42, green: 0.66, blue: 0.70),
                    highlight: Color(red: 0.62, green: 0.82, blue: 0.84)
                )
                .clipShape(
                    Path { path in
                        path.move(to: CGPoint(x: 8, y: 18))
                        path.addQuadCurve(to: CGPoint(x: 72, y: 17), control: CGPoint(x: 40, y: 40))
                        path.addLine(to: CGPoint(x: 66, y: 52))
                        path.addQuadCurve(to: CGPoint(x: 14, y: 53), control: CGPoint(x: 40, y: 60))
                        path.closeSubpath()
                    }
                )
            }
            .overlay {
                Path { path in
                    path.move(to: CGPoint(x: 8, y: 18))
                    path.addQuadCurve(to: CGPoint(x: 72, y: 17), control: CGPoint(x: 40, y: 40))
                    path.addLine(to: CGPoint(x: 66, y: 52))
                    path.addQuadCurve(to: CGPoint(x: 14, y: 53), control: CGPoint(x: 40, y: 60))
                    path.closeSubpath()
                }
                .stroke(HandDrawnPalette.ink.opacity(0.38), lineWidth: 1.8)
            }

            HStack(spacing: 5) {
                Circle().fill(Color.pink.opacity(0.78)).frame(width: 10, height: 10)
                Circle().fill(Color.orange.opacity(0.78)).frame(width: 8, height: 8)
                Circle().fill(Color.green.opacity(0.68)).frame(width: 9, height: 9)
            }
            .offset(y: -8)
        }
        .frame(width: 80, height: 56)
        .handDrawnShadow(radius: 4, y: 2)
    }
}

struct CornerDoodlesView: View {
    var body: some View {
        Canvas { context, size in
            var paw = Path()
            paw.addEllipse(in: CGRect(x: 2, y: 10, width: 10, height: 8))
            paw.addEllipse(in: CGRect(x: 0, y: 2, width: 5, height: 5))
            paw.addEllipse(in: CGRect(x: 6, y: 0, width: 5, height: 5))
            paw.addEllipse(in: CGRect(x: 12, y: 3, width: 5, height: 5))
            context.stroke(paw, with: .color(HandDrawnPalette.ink.opacity(0.28)), lineWidth: 1.2)

            var leaf = Path()
            leaf.move(to: CGPoint(x: 26, y: 16))
            leaf.addQuadCurve(to: CGPoint(x: 40, y: 4), control: CGPoint(x: 28, y: 2))
            leaf.addQuadCurve(to: CGPoint(x: 26, y: 16), control: CGPoint(x: 40, y: 14))
            context.stroke(leaf, with: .color(HandDrawnPalette.ink.opacity(0.28)), lineWidth: 1.2)
        }
        .frame(width: 46, height: 22)
    }
}
