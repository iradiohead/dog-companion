import SwiftUI

// MARK: - Procedural paper & watercolor texture (Cat On Chair–style warmth)

enum HandDrawnTexture {
  static func hash(_ seed: Int, _ salt: Int) -> Int {
    var value = seed &* 31 &+ salt &* 17
    value ^= value >> 13
  value &*= 1_677_761_9
    value ^= value >> 16
    return abs(value)
  }
}

struct PaperGrainOverlay: View {
  var opacity: Double = 0.55
  var dotCount: Int = 1_200

  var body: some View {
    Canvas { context, size in
      guard size.width > 1, size.height > 1 else { return }
      let width = Int(size.width)
      let height = Int(size.height)

      for index in 0..<dotCount {
        let x = CGFloat(HandDrawnTexture.hash(index, 1) % width)
        let y = CGFloat(HandDrawnTexture.hash(index, 2) % height)
        let tone = Double(HandDrawnTexture.hash(index, 3) % 100) / 100
        let radius = CGFloat(HandDrawnTexture.hash(index, 4) % 4) * 0.35 + 0.4
        let alpha = opacity * (0.015 + tone * 0.04)
        let color = tone > 0.55
          ? Color(white: 0.15).opacity(alpha)
          : Color(white: 0.95).opacity(alpha * 0.8)

        context.fill(
          Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius)),
          with: .color(color)
        )
      }

      for index in 0..<28 {
        let y = CGFloat(HandDrawnTexture.hash(index, 9) % height)
        let startX = CGFloat(HandDrawnTexture.hash(index, 10) % max(width / 4, 1))
        let endX = startX + CGFloat(HandDrawnTexture.hash(index, 11) % max(width / 2, 1))
        var path = Path()
        path.move(to: CGPoint(x: startX, y: y))
        path.addQuadCurve(
          to: CGPoint(x: endX, y: y + CGFloat(HandDrawnTexture.hash(index, 12) % 5) - 2),
          control: CGPoint(x: (startX + endX) / 2, y: y - 1)
        )
        context.stroke(
          path,
          with: .color(HandDrawnPalette.ink.opacity(opacity * 0.025)),
          lineWidth: 0.6
        )
      }
    }
    .blendMode(.multiply)
    .allowsHitTesting(false)
  }
}

struct WatercolorWashOverlay: View {
  let colors: [Color]

  var body: some View {
    ZStack {
      ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
        Ellipse()
          .fill(
            RadialGradient(
              colors: [color.opacity(0.35), color.opacity(0.08), .clear],
              center: washCenter(for: index),
              startRadius: 8,
              endRadius: 180
            )
          )
          .offset(washOffset(for: index))
          .blur(radius: 18)
      }
    }
    .blendMode(.multiply)
    .allowsHitTesting(false)
  }

  private func washCenter(for index: Int) -> UnitPoint {
    switch index % 3 {
    case 0: .topLeading
    case 1: .bottomTrailing
    default: .center
    }
  }

  private func washOffset(for index: Int) -> CGSize {
    switch index % 3 {
    case 0: CGSize(width: -40, height: -30)
    case 1: CGSize(width: 50, height: 40)
    default: CGSize(width: 0, height: 10)
    }
  }
}

struct SceneAmbientOverlay: View {
  let wallColor: Color
  let floorColor: Color
  let isLampLit: Bool

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [wallColor.opacity(0.22), .clear, floorColor.opacity(0.18)],
        startPoint: .top,
        endPoint: .bottom
      )

      RadialGradient(
        colors: [.clear, HandDrawnPalette.ink.opacity(0.06)],
        center: .center,
        startRadius: 120,
        endRadius: 420
      )

      if isLampLit {
        RadialGradient(
          colors: [
            HandDrawnPalette.warmGlow.opacity(0.22),
            HandDrawnPalette.warmGlow.opacity(0.06),
            .clear
          ],
          center: UnitPoint(x: 0.82, y: 0.38),
          startRadius: 20,
          endRadius: 260
        )
        .blendMode(.plusLighter)
      }
    }
    .allowsHitTesting(false)
  }
}

struct HandDrawnSketchStroke: Shape {
  let inset: CGFloat
  let wobble: CGFloat

  func path(in rect: CGRect) -> Path {
    let r = rect.insetBy(dx: inset, dy: inset)
    var path = Path()
    let points: [CGPoint] = [
      CGPoint(x: r.minX + wobble, y: r.minY),
      CGPoint(x: r.maxX, y: r.minY + wobble * 0.6),
      CGPoint(x: r.maxX - wobble * 0.4, y: r.maxY),
      CGPoint(x: r.minX, y: r.maxY - wobble * 0.5)
    ]
    path.move(to: points[0])
    for index in 1..<points.count {
      let previous = points[index - 1]
      let current = points[index]
      let control = CGPoint(
        x: (previous.x + current.x) / 2 + wobble * 0.3,
        y: (previous.y + current.y) / 2 - wobble * 0.2
      )
      path.addQuadCurve(to: current, control: control)
    }
    path.closeSubpath()
    return path
  }
}

extension View {
  func paperTextured(opacity: Double = 0.5) -> some View {
    overlay { PaperGrainOverlay(opacity: opacity) }
  }

  func handDrawnShadow(
    color: Color = HandDrawnPalette.ink.opacity(0.14),
    radius: CGFloat = 6,
    y: CGFloat = 4
  ) -> some View {
    shadow(color: color, radius: radius, x: 0, y: y)
      .shadow(color: color.opacity(0.45), radius: radius * 0.4, x: 1, y: 1)
  }

  func watercolorFill(_ base: Color, highlight: Color? = nil) -> some View {
    let glow = highlight ?? base.opacity(0.65)
    return background {
      ZStack {
        base
        RadialGradient(
          colors: [glow.opacity(0.55), base.opacity(0.85), base.opacity(0.95)],
          center: UnitPoint(x: 0.32, y: 0.28),
          startRadius: 4,
          endRadius: 120
        )
        RadialGradient(
          colors: [.clear, HandDrawnPalette.ink.opacity(0.08)],
          center: UnitPoint(x: 0.72, y: 0.78),
          startRadius: 8,
          endRadius: 100
        )
      }
    }
  }
}
