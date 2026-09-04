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
    @State private var images: CachedPoseImages

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
        _images = State(initialValue: CachedPoseImages(poses.withSynthesizedFallbacks()))
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { context in
            let elapsed = context.date.timeIntervalSince(motionStarted)
            let snapshot = PosePlayback.snapshot(
                state: motionState,
                elapsed: elapsed,
                runDistance: runDistance
            )
            character(snapshot)
                .transaction { $0.animation = nil }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .onAppear {
            images = CachedPoseImages(poses.withSynthesizedFallbacks())
            motionStarted = Date()
        }
        .onChange(of: poses) { _, newPoses in
            images = CachedPoseImages(newPoses.withSynthesizedFallbacks())
        }
        .onChange(of: motionState) { _, _ in
            motionStarted = Date()
        }
    }

    private func character(_ snapshot: PoseSnapshot) -> some View {
        let travel = snapshot.travel
        return ZStack(alignment: .bottom) {
            Ellipse()
                .fill(Color.black.opacity(travel.shadowOpacity * travel.opacity))
                .frame(width: 78.0 * travel.shadowScale, height: 14.0 * travel.shadowScale)
                .offset(x: travel.x, y: 7)
                .blur(radius: 0.6)

            if travel.dust > 0.05 {
                dustPuffs(intensity: travel.dust)
                    .offset(x: travel.x - 22, y: 8)
                    .opacity(travel.opacity)
            }

            if travel.motion > 0.08 {
                SpeedStreaksView(intensity: travel.motion)
                    .frame(width: 56, height: 72)
                    .offset(x: travel.x - 62, y: travel.y - 34)
                    .opacity(travel.opacity)
            }

            poseStack(snapshot)
                .scaleEffect(x: travel.scaleX, y: travel.scaleY, anchor: .bottom)
                .rotationEffect(.degrees(Double(travel.rotationDegrees)), anchor: .bottom)
                .offset(x: travel.x, y: travel.y)
                .opacity(travel.opacity)
                .onTapGesture(perform: onTap)
        }
    }

    @ViewBuilder
    private func poseStack(_ snapshot: PoseSnapshot) -> some View {
        ZStack(alignment: .bottom) {
            if let image = images.image(for: snapshot.pose) {
                dogImage(image)
                    .opacity(1 - snapshot.crossfade)
            }
            if snapshot.crossfade > 0.02,
               snapshot.nextPose != snapshot.pose,
               let image = images.image(for: snapshot.nextPose) {
                dogImage(image)
                    .opacity(snapshot.crossfade)
            } else if snapshot.crossfade > 0.02, images.image(for: snapshot.pose) == nil {
                placeholderDog
                    .opacity(snapshot.crossfade)
            }
        }
    }

    private func dogImage(_ image: PlatformImage) -> some View {
        Image(platformImage: image)
            .interpolation(.high)
            .resizable()
            .scaledToFit()
    }

    private var placeholderDog: some View {
        Image(systemName: "dog.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.secondary)
            .padding(36)
    }

    private func dustPuffs(intensity: Double) -> some View {
        HStack(spacing: 7) {
            Capsule()
                .fill(HandDrawnPalette.ink.opacity(0.16 * intensity))
                .frame(width: CGFloat(11.0 + 10.0 * intensity), height: 5)
            Capsule()
                .fill(HandDrawnPalette.inkLight.opacity(0.14 * intensity))
                .frame(width: CGFloat(8.0 + 7.0 * intensity), height: 4)
                .offset(y: 1)
        }
        .allowsHitTesting(false)
    }
}

private struct CachedPoseImages {
    var sit: PlatformImage?
    var runA: PlatformImage?
    var runB: PlatformImage?
    var land: PlatformImage?

    init(_ set: PoseCutoutSet) {
        sit = set.sit.flatMap(PlatformImage.from)
        runA = set.runA.flatMap(PlatformImage.from)
        runB = set.runB.flatMap(PlatformImage.from)
        land = set.land.flatMap(PlatformImage.from)
    }

    func image(for pose: CompanionPose) -> PlatformImage? {
        switch pose {
        case .sit:
            return sit
        case .runA:
            return runA ?? runB ?? sit
        case .runB:
            return runB ?? runA ?? sit
        case .land:
            return land ?? sit
        }
    }
}

private struct SpeedStreaksView: View {
    var intensity: Double

    var body: some View {
        Canvas { context, size in
            guard intensity > 0.04 else { return }
            for index in 0..<3 {
                var stroke = Path()
                let y = size.height * (CGFloat(0.28) + CGFloat(0.2) * CGFloat(index))
                let length = CGFloat(18) + CGFloat(index) * CGFloat(8)
                stroke.move(to: CGPoint(x: 4, y: y))
                stroke.addQuadCurve(
                    to: CGPoint(x: length, y: y + 1.2),
                    control: CGPoint(x: length * CGFloat(0.5), y: y - 2.4)
                )
                context.stroke(
                    stroke,
                    with: .color(HandDrawnPalette.ink.opacity(0.12 + 0.1 * intensity)),
                    lineWidth: 1.3
                )
            }
        }
        .allowsHitTesting(false)
    }
}
