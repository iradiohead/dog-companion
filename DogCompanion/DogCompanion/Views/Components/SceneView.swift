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
            let floorHeight = max(geo.size.height * 0.66, 280)
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
        let rugWidth = min(width * 0.96, 420)
        let rugHeight: CGFloat = min(176, max(132, height * 0.48))
        let clusterLift: CGFloat = max(64, height * 0.18)

        return ZStack(alignment: .bottom) {
            WoodenFloorView(
                floorColor: scene.bottomColor.opacity(0.5),
                plankColor: HandDrawnPalette.ink
            )

            PrototypeRugView(color: rugColor)
                .frame(width: rugWidth, height: rugHeight)
                .padding(.bottom, clusterLift)

            HStack(alignment: .bottom, spacing: 18) {
                StudyDeskView(topColor: HandDrawnPalette.wood)
                    .scaleEffect(1.08)
                FloorLampView(
                    isLit: isFocusActive,
                    accent: Color(red: 0.95, green: 0.68, blue: 0.38)
                )
                .scaleEffect(1.12)
            }
            .padding(.bottom, clusterLift + rugHeight * 0.52)

            MotionView(
                sitImage: sitImage,
                palette: palette,
                motionState: motionState,
                runDistance: min(PosePlayback.runDistance, max(110, width * 0.38)),
                onTap: onCompanionTap
            )
            .frame(height: 210, alignment: .bottom)
            .padding(.bottom, clusterLift + 22)

            FoodBowlView()
                .scaleEffect(1.15)
                .padding(.bottom, clusterLift + 18)
                .offset(x: min(96, rugWidth * 0.26))
        }
    }

    private var rugColor: Color {
        scene.accentColor.opacity(0.85)
    }
}
