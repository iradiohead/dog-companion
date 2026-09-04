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
    @State private var breathing = false
    @State private var displayPoses: PoseCutoutSet

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
        _displayPoses = State(initialValue: poses.withSynthesizedFallbacks())
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.07, paused: false)) { context in
            let elapsed = context.date.timeIntervalSince(motionStarted)
            let pose = PosePlayback.pose(state: motionState, elapsed: elapsed)
            let travel = PosePlayback.travel(
                state: motionState,
                elapsed: elapsed,
                runDistance: runDistance
            )
            frame(for: pose, travel: travel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .onAppear {
            displayPoses = poses.withSynthesizedFallbacks()
            motionStarted = Date()
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                breathing = true
            }
        }
        .onChange(of: poses) { _, newPoses in
            displayPoses = newPoses.withSynthesizedFallbacks()
        }
        .onChange(of: motionState) { _, _ in
            motionStarted = Date()
        }
    }

    @ViewBuilder
    private func frame(for pose: CompanionPose, travel: PoseTravel) -> some View {
        if let data = displayPoses.data(for: pose), let uiImage = PlatformImage.from(data: data) {
            Image(platformImage: uiImage)
                .interpolation(.high)
                .resizable()
                .scaledToFit()
                .compositingGroup()
                .shadow(color: .black.opacity(0.12 * travel.opacity), radius: 4, y: 3)
                .scaleEffect(
                    x: travel.scale * idleBreathX,
                    y: travel.scale * idleBreathY,
                    anchor: .bottom
                )
                .offset(x: travel.x, y: travel.y)
                .opacity(travel.opacity)
                .onTapGesture(perform: onTap)
        } else if motionState != .away {
            Image(systemName: "dog.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
                .padding(36)
                .offset(x: travel.x, y: travel.y)
                .opacity(travel.opacity)
        }
    }

    private var idleBreathY: CGFloat {
        motionState == .idle && breathing ? 1.02 : 1
    }

    private var idleBreathX: CGFloat {
        motionState == .idle && breathing ? 0.985 : 1
    }
}
