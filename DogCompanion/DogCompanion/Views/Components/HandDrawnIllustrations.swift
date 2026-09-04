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
                    .frame(width: 92, height: 40)

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
                .frame(width: 18, height: 148)

                WobblyEllipse(wobble: 1.2, seed: 12)
                    .fill(HandDrawnPalette.ink.opacity(0.16))
                    .frame(width: 58, height: 14)
            }
        }
        .frame(width: 108, height: 204)
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
                        .frame(width: 168, height: 18)

                    deskLamp
                        .offset(x: 18, y: -22)

                    openNotebook
                        .offset(x: 96, y: -24)
                }
                .frame(height: 18)

                HStack(spacing: 124) {
                    deskLeg
                    deskLeg
                }
            }

            BlobShadow(width: 154, height: 13)
                .offset(y: 6)
        }
        .frame(width: 176, height: 108)
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
            .frame(width: 7, height: 68)
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

struct PrototypeRugView: View {
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                PerspectiveRugShape(farScale: 0.56, nearScale: 1.0)
                    .fill(HandDrawnPalette.ink.opacity(0.16))
                    .offset(y: 7)
                    .blur(radius: 5)

                Canvas { context, canvasSize in
                    drawRug(in: &context, size: canvasSize)
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .allowsHitTesting(false)
    }

    private func drawRug(in context: inout GraphicsContext, size: CGSize) {
        let body = PerspectiveRugShape(farScale: 0.58, nearScale: 0.98).path(in: CGRect(origin: .zero, size: size))
        let inner = PerspectiveRugShape(farScale: 0.48, nearScale: 0.82).path(
            in: CGRect(
                x: size.width * 0.09,
                y: size.height * 0.22,
                width: size.width * 0.82,
                height: size.height * 0.58
            )
        )
        let lip = nearLipPath(size: size)

        context.fill(
            body,
            with: .linearGradient(
                Gradient(colors: [
                    color.lighter(by: 0.16),
                    color,
                    color.darker(by: 0.14)
                ]),
                startPoint: CGPoint(x: size.width * 0.5, y: size.height * 0.12),
                endPoint: CGPoint(x: size.width * 0.5, y: size.height * 0.92)
            )
        )

        var pigment = context
        pigment.clip(to: body)
        pigment.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .radialGradient(
                Gradient(colors: [
                    Color.white.opacity(0.22),
                    .clear
                ]),
                center: CGPoint(x: size.width * 0.38, y: size.height * 0.34),
                startRadius: 8,
                endRadius: size.width * 0.42
            )
        )

        context.stroke(body, with: .color(HandDrawnPalette.ink.opacity(0.16)), lineWidth: 4.2)
        context.stroke(body, with: .color(HandDrawnPalette.ink.opacity(0.38)), lineWidth: 1.7)
        context.stroke(inner, with: .color(HandDrawnPalette.ink.opacity(0.18)), lineWidth: 1.4)

        context.fill(lip, with: .color(color.darker(by: 0.22).opacity(0.85)))
        context.stroke(lip, with: .color(HandDrawnPalette.ink.opacity(0.28)), lineWidth: 1.1)

        drawFringe(in: &context, size: size)
        drawWeave(in: &context, size: size)
    }

    private func nearLipPath(size: CGSize) -> Path {
        let midX = size.width * 0.5
        let nearW = size.width * 0.98
        let bottom = size.height * 0.90
        var path = Path()
        path.move(to: CGPoint(x: midX - nearW * 0.5, y: bottom - 2))
        path.addQuadCurve(
            to: CGPoint(x: midX + nearW * 0.5, y: bottom - 2),
            control: CGPoint(x: midX, y: bottom + 5)
        )
        path.addLine(to: CGPoint(x: midX + nearW * 0.5 - 4, y: bottom + 8))
        path.addQuadCurve(
            to: CGPoint(x: midX - nearW * 0.5 + 4, y: bottom + 8),
            control: CGPoint(x: midX, y: bottom + 13)
        )
        path.closeSubpath()
        return path
    }

    private func drawFringe(in context: inout GraphicsContext, size: CGSize) {
        let midX = size.width * 0.5
        let nearCount = 22
        let nearW = size.width * 0.96
        let bottom = size.height * 0.90
        for index in 0..<nearCount {
            let t = CGFloat(index) / CGFloat(nearCount - 1)
            let x = midX - nearW * 0.5 + nearW * t
            let flare = (t - 0.5) * 10
            var line = Path()
            line.move(to: CGPoint(x: x, y: bottom + 6))
            line.addLine(to: CGPoint(x: x + flare, y: bottom + 16))
            context.stroke(line, with: .color(HandDrawnPalette.ink.opacity(0.28)), lineWidth: 1.05)
        }

        let farCount = 14
        let farW = size.width * 0.56
        let top = size.height * 0.14
        for index in 0..<farCount {
            let t = CGFloat(index) / CGFloat(farCount - 1)
            let x = midX - farW * 0.5 + farW * t
            var line = Path()
            line.move(to: CGPoint(x: x, y: top))
            line.addLine(to: CGPoint(x: x, y: top - 5))
            context.stroke(line, with: .color(HandDrawnPalette.ink.opacity(0.16)), lineWidth: 0.8)
        }
    }

    private func drawWeave(in context: inout GraphicsContext, size: CGSize) {
        let midX = size.width * 0.5
        for index in 1..<5 {
            let t = CGFloat(index) / 5.0
            let y = size.height * (0.22 + t * 0.58)
            let width = size.width * (0.58 + t * 0.36)
            var stitch = Path()
            stitch.move(to: CGPoint(x: midX - width * 0.5, y: y))
            stitch.addQuadCurve(
                to: CGPoint(x: midX + width * 0.5, y: y + 1),
                control: CGPoint(x: midX, y: y - 3)
            )
            context.stroke(stitch, with: .color(HandDrawnPalette.ink.opacity(0.07 + Double(t) * 0.05)), lineWidth: 1)
        }
    }
}

struct PerspectiveRugShape: Shape {
    var farScale: CGFloat = 0.58
    var nearScale: CGFloat = 0.98

    func path(in rect: CGRect) -> Path {
        let midX = rect.midX
        let top = rect.minY + rect.height * 0.14
        let bottom = rect.maxY - rect.height * 0.10
        let farW = rect.width * farScale
        let nearW = rect.width * nearScale
        let midY = (top + bottom) * 0.5

        var path = Path()
        let topLeft = CGPoint(x: midX - farW * 0.5, y: top)
        let topRight = CGPoint(x: midX + farW * 0.5, y: top)
        let bottomRight = CGPoint(x: midX + nearW * 0.5, y: bottom)
        let bottomLeft = CGPoint(x: midX - nearW * 0.5, y: bottom)

        path.move(to: topLeft)
        path.addQuadCurve(to: topRight, control: CGPoint(x: midX, y: top - 5))
        path.addQuadCurve(
            to: bottomRight,
            control: CGPoint(x: midX + (farW + nearW) * 0.28, y: midY)
        )
        path.addQuadCurve(to: bottomLeft, control: CGPoint(x: midX, y: bottom + 7))
        path.addQuadCurve(
            to: topLeft,
            control: CGPoint(x: midX - (farW + nearW) * 0.28, y: midY)
        )
        path.closeSubpath()
        return path
    }
}

struct FoodBowlView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            WobblyEllipse(wobble: 1.1, seed: 90)
                .fill(HandDrawnPalette.ink.opacity(0.12))
                .frame(width: 58, height: 12)
                .offset(y: 2)

            WobblyEllipse(wobble: 1.6, seed: 91)
                .fill(Color(red: 0.86, green: 0.78, blue: 0.68))
                .overlay {
                    WatercolorPigment(
                        color: Color(red: 0.86, green: 0.78, blue: 0.68),
                        highlight: Color(red: 0.96, green: 0.90, blue: 0.82)
                    )
                    .clipShape(WobblyEllipse(wobble: 1.6, seed: 91))
                }
                .overlay {
                    WobblyEllipse(wobble: 1.8, seed: 92)
                        .stroke(HandDrawnPalette.ink.opacity(0.38), lineWidth: 1.5)
                }
                .frame(width: 54, height: 22)

            WobblyEllipse(wobble: 1.4, seed: 93)
                .fill(Color(red: 0.62, green: 0.42, blue: 0.28))
                .overlay {
                    WobblyEllipse(wobble: 1.2, seed: 94)
                        .stroke(HandDrawnPalette.ink.opacity(0.22), lineWidth: 1)
                }
                .frame(width: 34, height: 10)
                .offset(y: -6)

            HStack(spacing: 4) {
                Circle()
                    .fill(Color(red: 0.78, green: 0.52, blue: 0.28))
                    .frame(width: 5, height: 5)
                Circle()
                    .fill(Color(red: 0.72, green: 0.46, blue: 0.24))
                    .frame(width: 4, height: 4)
                Circle()
                    .fill(Color(red: 0.82, green: 0.58, blue: 0.32))
                    .frame(width: 5, height: 5)
            }
            .offset(y: -6)
        }
        .frame(width: 62, height: 28)
        .handDrawnShadow(radius: 3, y: 2)
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
