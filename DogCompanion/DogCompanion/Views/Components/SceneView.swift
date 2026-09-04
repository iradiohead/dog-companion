import SwiftUI

struct SceneView: View {
    let scene: SceneBackground
    let furniture: FurnitureItem
    let poses: PoseCutoutSet
    let motionState: CompanionMotionState
    let isFocusActive: Bool
    let onCompanionTap: () -> Void

    @State private var restFrame: CGRect = .zero

    var body: some View {
        GeometryReader { geo in
            let floorHeight = max(geo.size.height * 0.40, 180)
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

                MotionView(
                    poses: poses,
                    motionState: motionState,
                    runDistance: restFrame == .zero
                        ? PosePlayback.runDistance
                        : max(96, restFrame.midX - 72),
                    onTap: onCompanionTap
                )
                .frame(width: 150, height: 168)
                .position(x: restFrame.midX, y: restFrame.midY)
                .opacity(restFrame == .zero ? 0 : 1)
                .zIndex(20)
            }
            .coordinateSpace(name: "focusScene")
            .onPreferenceChange(DogRestAnchorKey.self) { restFrame = $0 }
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
                    ZStack(alignment: .bottom) {
                        DogMatView(color: furniture.tint.opacity(0.9))
                            .frame(width: 190, height: 50)
                            .padding(.bottom, 4)

                        Color.clear
                            .frame(width: 150, height: 168)
                            .padding(.bottom, 8)
                            .anchorReader(coordinateSpace: "focusScene")
                    }
                    .frame(width: 190)

                    StudyDeskView(topColor: HandDrawnPalette.wood)
                        .scaleEffect(1.05)
                        .padding(.bottom, 2)
                }

                Spacer(minLength: 12)

                CornerDoodlesView()
                    .padding(.trailing, 22)
                    .padding(.bottom, 18)
            }
            .padding(.bottom, 8)
        }
    }
}

private struct DogRestAnchorKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero {
            value = next
        }
    }
}

private extension View {
    func anchorReader(coordinateSpace: String) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: DogRestAnchorKey.self,
                    value: proxy.frame(in: .named(coordinateSpace))
                )
            }
        )
    }
}
