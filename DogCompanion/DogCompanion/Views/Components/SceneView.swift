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
            }
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
                floorColor: scene.bottomColor.opacity(0.42),
                plankColor: HandDrawnPalette.ink
            )
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(HandDrawnPalette.ink.opacity(0.1))
                    .frame(height: 2)
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

                        MotionView(
                            cutoutData: cutoutData,
                            portraitData: nil,
                            motionState: motionState,
                            onTap: onCompanionTap
                        )
                        .frame(width: 150, height: 150)
                        .padding(.bottom, 8)
                    }

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
