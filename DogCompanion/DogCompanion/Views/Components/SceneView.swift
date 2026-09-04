import SwiftUI

struct SceneView: View {
    let scene: SceneBackground
    let furniture: FurnitureItem
    let sitImage: PlatformImage?
    let palette: CoatPalette
    let motionState: CompanionMotionState
    let isFocusActive: Bool
    let onCompanionTap: () -> Void

    @State private var motionStarted = Date()

    var body: some View {
        GeometryReader { geo in
            let floorHeight = max(geo.size.height * 0.56, 240)
            let wallHeight = geo.size.height - floorHeight

            ZStack(alignment: .top) {
                SceneAmbientOverlay(
                    wallColor: scene.topColor,
                    floorColor: scene.bottomColor,
                    isLampLit: isFocusActive
                )

                VStack(spacing: 0) {
                    wallArea(width: geo.size.width, height: wallHeight)
                        .frame(height: wallHeight)

                    floorArea(width: geo.size.width, height: floorHeight)
                        .frame(height: floorHeight)
                }
            }
        }
        .onAppear { motionStarted = Date() }
        .onChange(of: motionState) { _, _ in
            motionStarted = Date()
        }
    }

    private func wallArea(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            LinearGradient(
                colors: [scene.topColor.opacity(0.18), .clear],
                startPoint: .top,
                endPoint: .bottom
            )

            WallPaintingView(accent: scene.accentColor)
                .scaleEffect(0.9)
                .position(x: width * 0.22, y: height * 0.58)

            FloorLampView(
                isLit: isFocusActive,
                accent: Color(red: 0.95, green: 0.68, blue: 0.38)
            )
            .scaleEffect(0.95)
            .position(x: width * 0.82, y: height * 0.72)
        }
    }

    private func floorArea(width: CGFloat, height: CGFloat) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
            let elapsed = context.date.timeIntervalSince(motionStarted)
            let inFront = PosePlayback.occlusion(state: motionState, elapsed: elapsed) == .inFront

            ZStack(alignment: .bottom) {
                WoodenFloorView(
                    floorColor: scene.bottomColor.opacity(0.5),
                    plankColor: HandDrawnPalette.ink
                )
                .overlay(alignment: .top) {
                    Canvas { context, size in
                        var horizon = Path()
                        horizon.move(to: CGPoint(x: 0, y: 3))
                        horizon.addQuadCurve(
                            to: CGPoint(x: size.width, y: 4),
                            control: CGPoint(x: size.width * 0.5, y: -2)
                        )
                        context.stroke(horizon, with: .color(HandDrawnPalette.ink.opacity(0.12)), lineWidth: 1.6)
                    }
                    .frame(height: 8)
                }

                HStack(alignment: .bottom, spacing: 0) {
                    GiftBasketView()
                        .scaleEffect(0.95)
                        .padding(.leading, 18)
                        .padding(.bottom, 14)

                    Spacer(minLength: 8)

                    HStack(alignment: .bottom, spacing: 6) {
                        chairStack(inFront: inFront)

                        StudyDeskView(topColor: HandDrawnPalette.wood)
                            .scaleEffect(1.05)
                            .padding(.bottom, 2)
                    }

                    Spacer(minLength: 12)

                    CornerDoodlesView()
                        .padding(.trailing, 22)
                        .padding(.bottom, 18)
                }
                .padding(.bottom, 36)
            }
        }
    }

    private func chairStack(inFront: Bool) -> some View {
        ZStack(alignment: .bottom) {
            LayeredChairView(
                color: furniture.tint,
                silhouette: furniture.silhouette,
                layer: .back
            )
            .zIndex(1)

            LayeredChairView(
                color: furniture.tint,
                silhouette: furniture.silhouette,
                layer: .seat
            )
            .zIndex(2)

            MotionView(
                sitImage: sitImage,
                palette: palette,
                motionState: motionState,
                hopDistance: PosePlayback.hopFrontY,
                onTap: onCompanionTap
            )
            .frame(
                width: 220,
                height: 196 + PosePlayback.hopFrontY,
                alignment: .bottom
            )
            .padding(.bottom, 62)
            .zIndex(inFront ? 6 : 3)

            LayeredChairView(
                color: furniture.tint,
                silhouette: furniture.silhouette,
                layer: .front
            )
            .zIndex(4)
        }
        .frame(width: 248, height: 300)
    }
}
