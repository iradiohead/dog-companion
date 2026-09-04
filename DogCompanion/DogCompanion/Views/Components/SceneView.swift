import SwiftUI

struct SceneView: View {
    let scene: SceneBackground
    let furniture: FurnitureItem
    let cutoutData: Data?
    let portraitData: Data?
    let motionState: CompanionMotionState
    let onCompanionTap: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [scene.topColor, scene.bottomColor],
                startPoint: .top,
                endPoint: .bottom
            )

            RoundedRectangle(cornerRadius: 20)
                .fill(scene.accentColor.opacity(0.25))
                .frame(height: 90)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

            VStack(spacing: 0) {
                Spacer()

                Image(systemName: furniture.iconName)
                    .font(.system(size: 72))
                    .foregroundStyle(furniture.tint)
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    .padding(.bottom, 8)

                MotionView(
                    cutoutData: cutoutData,
                    portraitData: portraitData,
                    motionState: motionState,
                    onTap: onCompanionTap
                )
                .padding(.bottom, 28)
            }
        }
        .frame(height: 360)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(.white.opacity(0.35), lineWidth: 1)
        }
    }
}
