import SwiftUI

struct SceneView: View {
    let scene: SceneBackground
    let sitImage: PlatformImage?
    let palette: CoatPalette
    let motionState: CompanionMotionState
    let isFocusActive: Bool
    let onCompanionTap: () -> Void

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
        }
    }

    private func floorArea(width: CGFloat, height: CGFloat) -> some View {
        let rugWidth = min(width * 0.88, 360)
        let rugHeight: CGFloat = min(128, height * 0.42)

        return ZStack(alignment: .bottom) {
            WoodenFloorView(
                floorColor: scene.bottomColor.opacity(0.5),
                plankColor: HandDrawnPalette.ink
            )

            PrototypeRugView(color: rugColor)
                .frame(width: rugWidth, height: rugHeight)
                .padding(.bottom, 32)

            HStack(alignment: .bottom, spacing: 28) {
                SideTableView(topColor: HandDrawnPalette.wood)
                    .scaleEffect(0.92)
                FloorLampView(
                    isLit: isFocusActive,
                    accent: Color(red: 0.95, green: 0.68, blue: 0.38)
                )
                .scaleEffect(0.78)
            }
            .padding(.bottom, 78)

            MotionView(
                sitImage: sitImage,
                palette: palette,
                motionState: motionState,
                runDistance: min(PosePlayback.runDistance, max(110, width * 0.38)),
                onTap: onCompanionTap
            )
            .frame(height: 200, alignment: .bottom)
            .padding(.bottom, 48)

            FoodBowlView()
                .padding(.bottom, 44)
                .offset(x: min(86, rugWidth * 0.28))
        }
    }

    private var rugColor: Color {
        scene.accentColor.opacity(0.85)
    }
}
