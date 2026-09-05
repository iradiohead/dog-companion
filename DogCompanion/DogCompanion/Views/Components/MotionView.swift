import SwiftUI

struct MotionView: View {
    let sitImage: PlatformImage?
    var runFrames: [PlatformImage] = []
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
            switch (oldState, newState) {
            case (.runningIn, .idle):
                motionStarted = Date()
            case (_, .runningIn), (_, .reacting), (_, .celebrating), (_, .away):
                motionStarted = Date()
            default:
                break
            }
        }
    }

    private func characterOpacity(travel: PoseTravel, elapsed: TimeInterval) -> Double {
        switch motionState {
        case .away:
            return 0
        case .idle, .reacting, .celebrating:
            return 1
        case .runningIn:
            return PosePlayback.runInOpacity(elapsed: elapsed)
        }
    }

    private func character(_ snapshot: PoseSnapshot, elapsed: TimeInterval) -> some View {
        let travel = snapshot.travel
        let opacity = characterOpacity(travel: travel, elapsed: elapsed)
        let showRunFlipbook = RunInPresentation.showsFlipbook(
            motion: motionState,
            facingScaleX: travel.facingScaleX,
            hasRunFrames: !runFrames.isEmpty
        )
        return ZStack(alignment: .bottom) {
            Ellipse()
                .fill(Color.black.opacity(travel.shadowOpacity * opacity))
                .frame(width: 74.0 * travel.shadowScale, height: 12.0 * travel.shadowScale)
                .offset(x: travel.x, y: 6)
                .blur(radius: 0.5)

            CompanionRigView(
                image: sitImage,
                runFrames: runFrames,
                palette: palette,
                state: CompanionRigMotion.rigState(from: motionState, elapsed: elapsed),
                elapsed: elapsed,
                isPaused: motionState == .away,
                motion: motionState,
                showRunFlipbook: showRunFlipbook,
                facingScaleX: travel.facingScaleX
            )
            .scaleEffect(x: travel.scaleX, y: travel.scaleY, anchor: .bottom)
            .rotationEffect(.degrees(Double(travel.rotationDegrees)), anchor: .bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .offset(x: travel.x, y: travel.y)
            .opacity(opacity)
            .onTapGesture(perform: onTap)
        }
    }
}
