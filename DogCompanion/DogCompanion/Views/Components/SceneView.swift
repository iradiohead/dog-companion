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
                // Wall
                LinearGradient(
                    colors: [scene.topColor, scene.bottomColor.opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Floor
                VStack {
                    Spacer()
                    WoodenFloorView(
                        floorColor: scene.accentColor.opacity(0.35),
                        plankColor: HandDrawnPalette.ink
                    )
                    .frame(height: geo.size.height * 0.32)
                }

                // Wall painting
                WallPaintingView(accent: scene.accentColor)
                    .position(x: geo.size.width * 0.72, y: geo.size.height * 0.18)

                // Floor lamp
                FloorLampView(isLit: isFocusActive, accent: scene.accentColor)
                    .position(x: geo.size.width * 0.14, y: geo.size.height * 0.52)

                // Table + dog area
                VStack {
                    Spacer()

                    HStack(alignment: .bottom, spacing: 0) {
                        VStack(spacing: 0) {
                            DogMatView(color: furniture.tint)
                                .padding(.bottom, 4)

                            MotionView(
                                cutoutData: cutoutData,
                                portraitData: portraitData,
                                motionState: motionState,
                                onTap: onCompanionTap
                            )
                            .frame(height: min(geo.size.height * 0.28, 220))
                        }
                        .frame(maxWidth: .infinity)

                        SideTableView(topColor: scene.accentColor.opacity(0.75))
                            .padding(.bottom, 18)
                            .padding(.trailing, 28)
                    }
                    .padding(.bottom, geo.size.height * 0.08)
                }
            }
        }
        .ignoresSafeArea()
    }
}
