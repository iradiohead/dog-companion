import SwiftUI
import UIKit

enum HandDrawnTexture {
    static func hash(_ seed: Int, _ salt: Int) -> Int {
        var value = seed &* 31 &+ salt &* 17
        value ^= value >> 13
        value &*= 1_677_761_9
        value ^= value >> 16
        return abs(value)
    }

    static func unit(_ seed: Int, _ salt: Int) -> CGFloat {
        CGFloat(hash(seed, salt) % 1_000) / 1_000
    }
}

enum HandDrawnFont {
    static func brush(_ size: CGFloat) -> Font {
        .custom("Kaiti SC", size: size)
    }

    static func marker(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// Directional paper fibers + sparse specks, closer to watercolor paper than digital noise.
struct PaperFiberOverlay: View {
    var opacity: Double = 0.55
    var seed: Int = 7

    var body: some View {
        Canvas { context, size in
            guard size.width > 2, size.height > 2 else { return }
            let width = size.width
            let height = size.height
            let fiberCount = Int(max(24.0, min(90.0, width * height / 4_800)))

            for index in 0..<fiberCount {
                let y = HandDrawnTexture.unit(index + seed, 1) * height
                let startX = HandDrawnTexture.unit(index, 2) * width * 0.7
                let length = 18 + HandDrawnTexture.unit(index, 3) * min(90, width * 0.35)
                let bend = (HandDrawnTexture.unit(index, 4) - 0.5) * 3
                var path = Path()
                path.move(to: CGPoint(x: startX, y: y))
                path.addQuadCurve(
                    to: CGPoint(x: min(width, startX + length), y: y + bend),
                    control: CGPoint(x: startX + length * 0.5, y: y - bend * 0.6)
                )
                context.stroke(
                    path,
                    with: .color(HandDrawnPalette.ink.opacity(opacity * 0.045)),
                    lineWidth: 0.6 + HandDrawnTexture.unit(index, 5) * 0.5
                )
            }

            let speckCount = Int(max(80.0, min(280.0, width * height / 1_600)))
            for index in 0..<speckCount {
                let x = HandDrawnTexture.unit(index + seed, 8) * width
                let y = HandDrawnTexture.unit(index, 9) * height
                let radius = 0.35 + HandDrawnTexture.unit(index, 10) * 1.1
                let dark = HandDrawnTexture.unit(index, 11) > 0.55
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius * 0.7)),
                    with: .color(
                        (dark ? HandDrawnPalette.ink : Color.white)
                            .opacity(opacity * (dark ? 0.05 : 0.07))
                    )
                )
            }
        }
        .blendMode(.multiply)
        .allowsHitTesting(false)
    }
}

struct PaperGrainOverlay: View {
    var opacity: Double = 0.55
    var dotCount: Int = 1_200

    var body: some View {
        PaperFiberOverlay(opacity: opacity, seed: max(1, dotCount / 40))
    }
}

struct PencilHatchOverlay: View {
    var color: Color = HandDrawnPalette.ink
    var opacity: Double = 0.12
    var density: Int = 28
    var angle: Double = -28

    var body: some View {
        Canvas { context, size in
            guard size.width > 2, size.height > 2 else { return }
            context.rotate(by: .degrees(angle))
            let span = max(size.width, size.height) * 1.6
            for index in 0..<density {
                let t = CGFloat(index) / CGFloat(max(density - 1, 1))
                let y = (t - 0.2) * span
                let wobble = (HandDrawnTexture.unit(index, 3) - 0.5) * 6
                var path = Path()
                path.move(to: CGPoint(x: -span * 0.2, y: y))
                path.addQuadCurve(
                    to: CGPoint(x: span, y: y + wobble),
                    control: CGPoint(x: span * 0.4, y: y - wobble * 0.5)
                )
                let weight = 0.45 + HandDrawnTexture.unit(index, 4) * 0.7
                context.stroke(
                    path,
                    with: .color(color.opacity(opacity * (0.45 + HandDrawnTexture.unit(index, 5) * 0.55))),
                    lineWidth: weight
                )
            }
        }
        .allowsHitTesting(false)
    }
}

struct WatercolorWashOverlay: View {
    let colors: [Color]

    var body: some View {
        Canvas { context, size in
            for (index, color) in colors.enumerated() {
                let cx = size.width * (0.18 + HandDrawnTexture.unit(index, 1) * 0.64)
                let cy = size.height * (0.16 + HandDrawnTexture.unit(index, 2) * 0.68)
                let radius = min(size.width, size.height) * (0.28 + HandDrawnTexture.unit(index, 3) * 0.22)
                var blob = Path()
                blob.addEllipse(in: CGRect(
                    x: cx - radius,
                    y: cy - radius * 0.82,
                    width: radius * 2.1,
                    height: radius * 1.7
                ))
                context.fill(
                    blob,
                    with: .radialGradient(
                        Gradient(colors: [
                            color.opacity(0.38),
                            color.opacity(0.12),
                            .clear
                        ]),
                        center: CGPoint(x: cx, y: cy),
                        startRadius: 4,
                        endRadius: radius * 1.15
                    )
                )
            }
        }
        .blur(radius: 16)
        .blendMode(.multiply)
        .allowsHitTesting(false)
    }
}

struct WatercolorPigment: View {
    let color: Color
    var highlight: Color? = nil

    var body: some View {
        ZStack {
            color

            RadialGradient(
                colors: [
                    (highlight ?? color.lighter(by: 0.18)).opacity(0.7),
                    color.opacity(0.15),
                    .clear
                ],
                center: UnitPoint(x: 0.3, y: 0.22),
                startRadius: 2,
                endRadius: 90
            )

            RadialGradient(
                colors: [
                    .clear,
                    color.darker(by: 0.12).opacity(0.28),
                    HandDrawnPalette.ink.opacity(0.1)
                ],
                center: UnitPoint(x: 0.78, y: 0.86),
                startRadius: 10,
                endRadius: 110
            )

            PencilHatchOverlay(color: color.darker(by: 0.25), opacity: 0.16, density: 18)
            PaperFiberOverlay(opacity: 0.28, seed: 11)
        }
        .allowsHitTesting(false)
    }
}

struct SceneAmbientOverlay: View {
    let wallColor: Color
    let floorColor: Color
    let isLampLit: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [wallColor.opacity(0.16), .clear, floorColor.opacity(0.22)],
                startPoint: .top,
                endPoint: .bottom
            )

            WatercolorWashOverlay(colors: [
                wallColor.opacity(0.55),
                HandDrawnPalette.cream,
                floorColor.opacity(0.7)
            ])

            RadialGradient(
                colors: [.clear, HandDrawnPalette.ink.opacity(0.07)],
                center: .center,
                startRadius: 90,
                endRadius: 460
            )

            if isLampLit {
                RadialGradient(
                    colors: [
                        HandDrawnPalette.warmGlow.opacity(0.28),
                        HandDrawnPalette.warmGlow.opacity(0.08),
                        .clear
                    ],
                    center: UnitPoint(x: 0.78, y: 0.42),
                    startRadius: 16,
                    endRadius: 240
                )
                .blendMode(.plusLighter)
            }

            PaperFiberOverlay(opacity: 0.4, seed: 3)
        }
        .allowsHitTesting(false)
    }
}

struct WobblyRoundedRectangle: Shape {
    var cornerRadius: CGFloat = 10
    var wobble: CGFloat = 2.4
    var seed: Int = 1

    func path(in rect: CGRect) -> Path {
        wobblyPath(around: roundedRectPoints(in: rect, cornerRadius: cornerRadius), wobble: wobble, seed: seed)
    }
}

struct WobblyEllipse: Shape {
    var wobble: CGFloat = 2.2
    var seed: Int = 2

    func path(in rect: CGRect) -> Path {
        var points: [CGPoint] = []
        let steps = 24
        for index in 0..<steps {
            let angle = (Double(index) / Double(steps)) * .pi * 2
            points.append(
                CGPoint(
                    x: rect.midX + Foundation.cos(angle) * rect.width / 2,
                    y: rect.midY + Foundation.sin(angle) * rect.height / 2
                )
            )
        }
        return wobblyPath(around: points, wobble: wobble, seed: seed, closed: true)
    }
}

struct HandDrawnSketchStroke: Shape {
    let inset: CGFloat
    let wobble: CGFloat

    func path(in rect: CGRect) -> Path {
        WobblyRoundedRectangle(cornerRadius: 6, wobble: wobble, seed: 4)
            .path(in: rect.insetBy(dx: inset, dy: inset))
    }
}

struct BlobShadow: View {
    var width: CGFloat = 120
    var height: CGFloat = 14

    var body: some View {
        WobblyEllipse(wobble: 1.4, seed: 9)
            .fill(
                RadialGradient(
                    colors: [
                        HandDrawnPalette.ink.opacity(0.16),
                        HandDrawnPalette.ink.opacity(0.04),
                        .clear
                    ],
                    center: .center,
                    startRadius: 2,
                    endRadius: width * 0.45
                )
            )
            .frame(width: width, height: height)
            .blur(radius: 1.2)
    }
}

extension View {
    func paperTextured(opacity: Double = 0.5) -> some View {
        overlay { PaperFiberOverlay(opacity: opacity) }
    }

    func pencilHatched(opacity: Double = 0.12) -> some View {
        overlay { PencilHatchOverlay(opacity: opacity) }
    }

    func handDrawnShadow(
        color: Color = HandDrawnPalette.ink.opacity(0.14),
        radius: CGFloat = 6,
        y: CGFloat = 4
    ) -> some View {
        shadow(color: color, radius: radius, x: 0.4, y: y)
            .shadow(color: color.opacity(0.35), radius: radius * 0.35, x: 1.2, y: 1)
    }

    func inkOutline(lineWidth: CGFloat = 1.8, opacity: Double = 0.45) -> some View {
        overlay {
            GeometryReader { geo in
                let radius = min(geo.size.width, geo.size.height) * 0.18
                ZStack {
                    WobblyRoundedRectangle(cornerRadius: radius, wobble: 1.8)
                        .stroke(HandDrawnPalette.ink.opacity(opacity * 0.4), lineWidth: lineWidth + 1.3)
                        .offset(x: 0.5, y: 0.7)
                    WobblyRoundedRectangle(cornerRadius: radius, wobble: 2.2, seed: 8)
                        .stroke(HandDrawnPalette.ink.opacity(opacity), lineWidth: lineWidth)
                }
            }
            .allowsHitTesting(false)
        }
    }

    func watercolorFill(_ base: Color, highlight: Color? = nil) -> some View {
        overlay {
            WatercolorPigment(color: base, highlight: highlight)
        }
        .clipped()
    }
}

extension Color {
    func lighter(by amount: CGFloat) -> Color {
        mix(with: .white, amount: amount)
    }

    func darker(by amount: CGFloat) -> Color {
        mix(with: HandDrawnPalette.ink, amount: amount)
    }

    func mix(with other: Color, amount: CGFloat) -> Color {
        let t = max(0 as CGFloat, min(1 as CGFloat, amount))
        let a = UIColor(self)
        let b = UIColor(other)
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        return Color(
            red: Double(ar + (br - ar) * t),
            green: Double(ag + (bg - ag) * t),
            blue: Double(ab + (bb - ab) * t),
            opacity: Double(aa + (ba - aa) * t)
        )
    }
}

private func roundedRectPoints(in rect: CGRect, cornerRadius: CGFloat) -> [CGPoint] {
    let radius = min(cornerRadius, min(rect.width, rect.height) / 2)
    var points: [CGPoint] = []
    let corners: [(CGPoint, CGFloat, CGFloat)] = [
        (CGPoint(x: rect.maxX - radius, y: rect.minY + radius), -.pi / 2, 0),
        (CGPoint(x: rect.maxX - radius, y: rect.maxY - radius), 0, .pi / 2),
        (CGPoint(x: rect.minX + radius, y: rect.maxY - radius), .pi / 2, .pi),
        (CGPoint(x: rect.minX + radius, y: rect.minY + radius), .pi, .pi * 1.5)
    ]
    for (center, start, end) in corners {
        for step in 0..<6 {
            let angle = start + (end - start) * CGFloat(step) / 5
            points.append(
                CGPoint(
                    x: center.x + Foundation.cos(Double(angle)) * radius,
                    y: center.y + Foundation.sin(Double(angle)) * radius
                )
            )
        }
    }
    return points
}

private func wobblyPath(around points: [CGPoint], wobble: CGFloat, seed: Int, closed: Bool = true) -> Path {
    guard points.count > 2 else { return Path() }
    var path = Path()
    let jittered: [CGPoint] = points.enumerated().map { index, point in
        let dx = (HandDrawnTexture.unit(index + seed, 1) - 0.5) * wobble * 2
        let dy = (HandDrawnTexture.unit(index + seed, 2) - 0.5) * wobble * 2
        return CGPoint(x: point.x + dx, y: point.y + dy)
    }
    path.move(to: jittered[0])
    for index in 1..<jittered.count {
        let previous = jittered[index - 1]
        let current = jittered[index]
        let control = CGPoint(
            x: (previous.x + current.x) / 2 + (HandDrawnTexture.unit(index, 3) - 0.5) * wobble,
            y: (previous.y + current.y) / 2 + (HandDrawnTexture.unit(index, 4) - 0.5) * wobble
        )
        path.addQuadCurve(to: current, control: control)
    }
    if closed {
        let last = jittered[jittered.count - 1]
        let first = jittered[0]
        let control = CGPoint(
            x: (last.x + first.x) / 2,
            y: (last.y + first.y) / 2 - wobble * 0.3
        )
        path.addQuadCurve(to: first, control: control)
        path.closeSubpath()
    }
    return path
}
