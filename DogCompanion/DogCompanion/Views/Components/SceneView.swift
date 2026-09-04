import SwiftUI

struct SceneView: View {
    let scene: SceneBackground
    let furniture: FurnitureItem
    let cutoutData: Data?
    let portraitData: Data?
    let motionState: CompanionMotionState
    let isFocusActive: Bool
    let onCompanionTap: () -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack {
                SceneAmbientOverlay(
                    wallColor: scene.topColor,
                    floorColor: scene.bottomColor,
                    isLampLit: isFocusActive
                )

                WallPaintingView(accent: scene.accentColor)
                    .scaleEffect(0.85)
                    .position(x: geo.size.width * 0.18, y: geo.size.height * 0.22)

                GiftBasketView()
                    .position(x: geo.size.width * 0.14, y: geo.size.height * 0.78)

                FloorLampView(isLit: isFocusActive, accent: Color(red: 0.95, green: 0.68, blue: 0.38))
                    .scaleEffect(0.9)
                    .position(x: geo.size.width * 0.84, y: geo.size.height * 0.42)

                CornerDoodlesView()
                    .position(x: geo.size.width * 0.88, y: geo.size.height * 0.82)

                VStack(spacing: 0) {
                    Spacer()

                    WoodenFloorView(
                        floorColor: scene.bottomColor.opacity(0.35),
                        plankColor: HandDrawnPalette.ink
                    )
                    .frame(height: min(geo.size.height * 0.14, 72))
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(HandDrawnPalette.ink.opacity(0.08))
                            .frame(height: 2)
                    }

                    HStack(alignment: .bottom, spacing: 8) {
                        Spacer(minLength: 0)

                        ZStack(alignment: .bottom) {
                            DogMatView(color: furniture.tint.opacity(0.92))
                                .padding(.bottom, 6)

                            MotionView(
                                cutoutData: cutoutData,
                                portraitData: portraitData,
                                motionState: motionState,
                                onTap: onCompanionTap
                            )
                            .frame(height: min(geo.size.height * 0.32, 140))
                            .padding(.bottom, 10)
                        }

                        StudyDeskView(topColor: HandDrawnPalette.wood)
                            .padding(.bottom, 4)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, geo.size.height * 0.03)
                }
            }
        }
    }
}
