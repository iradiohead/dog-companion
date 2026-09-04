import SwiftUI

struct MotionView: View {
    let palette: CoatPalette
    let motionState: CompanionMotionState
    var hopDistance: CGFloat = PosePlayback.hopDistance
    let onTap: () -> Void

    @State private var motionStarted = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { context in
            let elapsed = context.date.timeIntervalSince(motionStarted)
            let snapshot = PosePlayback.snapshot(
                state: motionState,
                elapsed: elapsed,
                runDistance: hopDistance
            )
            character(snapshot, elapsed: elapsed)
                .padding(.bottom, PosePlayback.hopFrontY)
                .transaction { $0.animation = nil }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .onAppear {
            motionStarted = Date()
        }
        .onChange(of: motionState) { _, _ in
            motionStarted = Date()
        }
    }

    private func character(_ snapshot: PoseSnapshot, elapsed: TimeInterval) -> some View {
        let travel = snapshot.travel
        return ZStack(alignment: .bottom) {
            Ellipse()
                .fill(Color.black.opacity(travel.shadowOpacity * travel.opacity))
                .frame(width: 74.0 * travel.shadowScale, height: 12.0 * travel.shadowScale)
                .offset(x: travel.x, y: 6)
                .blur(radius: 0.5)

            CompanionRigView(
                palette: palette,
                state: CompanionRigMotion.rigState(from: motionState),
                elapsed: elapsed,
                isPaused: motionState == .away
            )
            .scaleEffect(x: travel.scaleX, y: travel.scaleY, anchor: .bottom)
            .rotationEffect(.degrees(Double(travel.rotationDegrees)), anchor: .bottom)
            .frame(width: 150, height: 168, alignment: .bottom)
            .offset(x: travel.x, y: travel.y)
            .opacity(travel.opacity)
            .onTapGesture(perform: onTap)
        }
    }
}
