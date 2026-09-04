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
            let floorHeight = max(geo.size.height * 0.58, 250)
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
                .scaleEffect(0.82)
                .position(x: width * 0.18, y: max(36, height * 0.42))
        }
    }

    private func floorArea(width: CGFloat, height: CGFloat) -> some View {
        let rugWidth = min(width * 0.90, 380)
        let rugHeight: CGFloat = min(150, max(118, height * 0.40))
        let floorPad: CGFloat = max(52, height * 0.13)
        let dogHeight: CGFloat = min(156, max(128, height * 0.42))

        return ZStack(alignment: .bottom) {
            WoodenFloorView(
                floorColor: scene.bottomColor.opacity(0.5),
                plankColor: HandDrawnPalette.ink
            )

            PrototypeRugView(color: rugColor)
                .frame(width: rugWidth, height: rugHeight)
                .padding(.bottom, floorPad)

            StudyDeskView(topColor: HandDrawnPalette.wood)
                .padding(.bottom, floorPad + rugHeight * 0.44)
                .offset(x: -rugWidth * 0.22)

            FloorLampView(
                isLit: isFocusActive,
                accent: Color(red: 0.95, green: 0.68, blue: 0.38)
            )
            .padding(.bottom, floorPad + rugHeight * 0.38)
            .offset(x: rugWidth * 0.30)

            MotionView(
                sitImage: sitImage,
                palette: palette,
                motionState: motionState,
                runDistance: min(PosePlayback.runDistance, max(96, width * 0.34)),
                onTap: onCompanionTap
            )
            .frame(height: dogHeight, alignment: .bottom)
            .padding(.bottom, floorPad + rugHeight * 0.05)
            .offset(x: -rugWidth * 0.06)

            FoodBowlView()
                .padding(.bottom, floorPad + rugHeight * 0.08)
                .offset(x: rugWidth * 0.28)
        }
    }

    private var rugColor: Color {
        scene.accentColor.opacity(0.85)
    }
}
