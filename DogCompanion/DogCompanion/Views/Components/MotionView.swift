import SwiftUI

struct MotionView: View {
    let sitImage: PlatformImage?
    let palette: CoatPalette
    let motionState: CompanionMotionState
    var runDistance: CGFloat = PosePlayback.runDistance
    let onTap: () -> Void

    @State private var motionStarted = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { context in
            let elapsed = context.date.timeIntervalSince(motionStarted)
            let snapshot = PosePlayback.snapshot(
                state: motionState,
                elapsed: elapsed,
                runDistance: runDistance
            )
            character(snapshot, elapsed: elapsed)
                .transaction { $0.animation = nil }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .onAppear {
            motionStarted = Date()
        }
        .onChange(of: motionState) { oldState, newState in
            if newState == .idle, oldState == .runningIn {
                return
            }
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
                image: sitImage,
                palette: palette,
                state: CompanionRigMotion.rigState(from: motionState, elapsed: elapsed),
                elapsed: elapsed,
                isPaused: motionState == .away,
                motion: motionState
            )
            .scaleEffect(x: travel.scaleX, y: travel.scaleY, anchor: .bottom)
            .rotationEffect(.degrees(Double(travel.rotationDegrees)), anchor: .bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .offset(x: travel.x, y: travel.y)
            .opacity(travel.opacity)
            .onTapGesture(perform: onTap)
        }
    }
}
