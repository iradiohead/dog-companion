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

                    ZStack(alignment: .bottom) {
                        DogMatView(color: furniture.tint.opacity(0.92))
                            .padding(.bottom, 8)

                        VStack(spacing: -18) {
                            MotionView(
                                cutoutData: cutoutData,
                                portraitData: portraitData,
                                motionState: motionState,
                                onTap: onCompanionTap
                            )
                            .frame(height: min(geo.size.height * 0.34, 150))
                            .zIndex(1)

                            ArmChairView(seatColor: HandDrawnPalette.chairGreen)
                                .padding(.bottom, 6)
                        }
                    }
                    .padding(.bottom, geo.size.height * 0.04)
                }
            }
        }
    }
}
