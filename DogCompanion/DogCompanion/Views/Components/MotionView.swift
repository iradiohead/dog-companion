import SwiftUI

enum CompanionMotionState: Equatable {
    case away
    case runningIn
    case idle
    case reacting
    case celebrating
}

struct MotionView: View {
    let poses: PoseCutoutSet
    let motionState: CompanionMotionState
    var runDistance: CGFloat = PosePlayback.runDistance
    let onTap: () -> Void

    @State private var motionStarted = Date()
    @State private var sitImage: PlatformImage?

    init(
        poses: PoseCutoutSet,
        motionState: CompanionMotionState,
        runDistance: CGFloat = PosePlayback.runDistance,
        onTap: @escaping () -> Void
    ) {
        self.poses = poses
        self.motionState = motionState
        self.runDistance = runDistance
        self.onTap = onTap
        _sitImage = State(initialValue: poses.sit.flatMap(PlatformImage.from))
    }

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
            sitImage = poses.sit.flatMap(PlatformImage.from)
            motionStarted = Date()
        }
        .onChange(of: poses) { _, newPoses in
            sitImage = newPoses.sit.flatMap(PlatformImage.from)
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

            Group {
                if let sitImage {
                    CompanionRigView(
                        image: sitImage,
                        state: CompanionRigMotion.rigState(from: motionState),
                        elapsed: elapsed,
                        isPaused: motionState == .away
                    )
                } else if motionState != .away {
                    Image(systemName: "dog.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.secondary)
                        .padding(36)
                }
            }
            .scaleEffect(x: travel.scaleX, y: travel.scaleY, anchor: .bottom)
            .rotationEffect(.degrees(Double(travel.rotationDegrees)), anchor: .bottom)
            .offset(x: travel.x, y: travel.y)
            .opacity(travel.opacity)
            .onTapGesture(perform: onTap)
        }
    }
}
