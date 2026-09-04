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
    @State private var runAImage: PlatformImage?
    @State private var runBImage: PlatformImage?
    @State private var landImage: PlatformImage?

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
        _runAImage = State(initialValue: poses.runA.flatMap(PlatformImage.from))
        _runBImage = State(initialValue: poses.runB.flatMap(PlatformImage.from))
        _landImage = State(initialValue: poses.land.flatMap(PlatformImage.from))
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
            loadImages(from: poses)
            motionStarted = Date()
        }
        .onChange(of: poses) { _, newPoses in
            loadImages(from: newPoses)
        }
        .onChange(of: motionState) { _, _ in
            motionStarted = Date()
        }
    }

    private func character(_ snapshot: PoseSnapshot, elapsed: TimeInterval) -> some View {
        var travel = snapshot.travel
        if isMissingRunArt(for: snapshot.pose) {
            travel.scaleX *= 1.20
            travel.scaleY *= 0.76
            travel.rotationDegrees -= 16
        }
        return ZStack(alignment: .bottom) {
            Ellipse()
                .fill(Color.black.opacity(travel.shadowOpacity * travel.opacity))
                .frame(width: 74.0 * travel.shadowScale, height: 12.0 * travel.shadowScale)
                .offset(x: travel.x, y: 6)
                .blur(radius: 0.5)

            Group {
                if let image = image(for: snapshot.pose) {
                    CompanionRigView(
                        image: image,
                        state: CompanionRigMotion.rigState(from: motionState, elapsed: elapsed),
                        elapsed: elapsed,
                        isPaused: motionState == .away,
                        sliceParts: shouldSlice(snapshot.pose, image: image)
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
            .frame(width: 150, height: 168, alignment: .bottom)
            .offset(x: travel.x, y: travel.y)
            .opacity(travel.opacity)
            .onTapGesture(perform: onTap)
        }
    }

    private func image(for pose: CompanionPose) -> PlatformImage? {
        switch pose {
        case .sit:
            return sitImage
        case .runA:
            return runAImage ?? runBImage ?? sitImage
        case .runB, .runC, .runD:
            return runBImage ?? runAImage ?? sitImage
        case .land:
            return landImage ?? sitImage
        }
    }

    private func shouldSlice(_ pose: CompanionPose, image: PlatformImage) -> Bool {
        switch pose {
        case .runA, .runB, .runC, .runD:
            return image === sitImage
        case .sit, .land:
            return true
        }
    }

    private func isMissingRunArt(for pose: CompanionPose) -> Bool {
        switch pose {
        case .runA, .runB, .runC, .runD:
            return runAImage == nil && runBImage == nil
        default:
            return false
        }
    }

    private func loadImages(from poses: PoseCutoutSet) {
        sitImage = poses.sit.flatMap(PlatformImage.from)
        runAImage = poses.runA.flatMap(PlatformImage.from)
        runBImage = poses.runB.flatMap(PlatformImage.from)
        landImage = poses.land.flatMap(PlatformImage.from)
    }
}
