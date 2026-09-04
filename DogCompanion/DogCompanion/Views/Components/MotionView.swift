import SwiftUI

enum CompanionMotionState: Equatable {
    /// Off the mat, waiting in the distance — like Cat On Chair before focus starts.
    case away
    /// Runs from the back of the room onto the mat, then sits.
    case runningIn
    case idle
    case reacting
    case celebrating
}

private struct DogPose: Equatable {
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var hop: CGFloat
    var squashY: CGFloat
    var lean: Double
    var opacity: Double

    static let hiddenFar = DogPose(x: 156, y: -58, scale: 0.32, hop: 0, squashY: 1, lean: -8, opacity: 0)
    static let far = DogPose(x: 156, y: -58, scale: 0.32, hop: 0, squashY: 1, lean: -8, opacity: 1)
    static let sitting = DogPose(x: 0, y: 0, scale: 1, hop: 0, squashY: 1, lean: 0, opacity: 1)

    static func running(progress: CGFloat, hop: CGFloat) -> DogPose {
        let t = max(0, min(1, progress))
        let eased = 1 - (1 - t) * (1 - t)
        return DogPose(
            x: 156 * (1 - eased),
            y: -58 * (1 - eased),
            scale: 0.32 + 0.68 * eased,
            hop: hop,
            squashY: hop < -4 ? 1.06 : 0.96,
            lean: -8 * (1 - eased),
            opacity: 1
        )
    }
}

struct MotionView: View {
    let cutoutData: Data?
    let portraitData: Data?
    let motionState: CompanionMotionState
    let onTap: () -> Void

    @State private var breathing = false
    @State private var pose = DogPose.hiddenFar
    @State private var reactionWiggle = false
    @State private var motionTask: Task<Void, Never>?

    private var imageData: Data? { cutoutData }

    var body: some View {
        Group {
            if let imageData, let uiImage = PlatformImage.from(data: imageData) {
                Image(platformImage: uiImage)
                    .interpolation(.high)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(x: 1, y: pose.squashY, anchor: .bottom)
                    .scaleEffect(pose.scale, anchor: .bottom)
                    .rotationEffect(.degrees(pose.lean + rotation), anchor: .bottom)
                    .offset(x: pose.x, y: pose.y + pose.hop + breathOffset)
                    .opacity(pose.opacity)
                    .compositingGroup()
                    .shadow(color: .black.opacity(pose.opacity * 0.12), radius: 4, y: 3)
                    .onTapGesture(perform: onTap)
            } else if motionState != .away {
                Image(systemName: "dog.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
                    .padding(36)
                    .scaleEffect(pose.scale, anchor: .bottom)
                    .offset(x: pose.x, y: pose.y + pose.hop)
                    .opacity(pose.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .onAppear {
            pose = motionState == .idle || motionState == .reacting || motionState == .celebrating
                ? .sitting
                : .hiddenFar
            applyMotion(for: motionState)
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                breathing = true
            }
        }
        .onChange(of: motionState) { _, newValue in
            applyMotion(for: newValue)
        }
        .onDisappear {
            motionTask?.cancel()
        }
    }

    private var breathOffset: CGFloat {
        motionState == .idle && breathing ? -3 : 0
    }

    private var rotation: Double {
        motionState == .reacting && reactionWiggle ? 3 : 0
    }

    private func applyMotion(for state: CompanionMotionState) {
        motionTask?.cancel()

        switch state {
        case .away:
            motionTask = Task { await runOffstage() }
        case .runningIn:
            motionTask = Task { await runInAndSit() }
        case .idle:
            withAnimation(.easeOut(duration: 0.2)) {
                pose = .sitting
            }
        case .reacting:
            reactionWiggle = true
            withAnimation(.spring(response: 0.22, dampingFraction: 0.55)) {
                pose.squashY = 1.04
            }
            motionTask = Task {
                try? await Task.sleep(nanoseconds: 200_000_000)
                reactionWiggle = false
                withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                    pose.squashY = 1
                }
            }
        case .celebrating:
            motionTask = Task { await celebrate() }
        }
    }

    @MainActor
    private func runInAndSit() async {
        pose = .far
        let hops = 5
        for step in 1...hops {
            guard !Task.isCancelled else { return }
            let progress = CGFloat(step) / CGFloat(hops)
            withAnimation(.easeOut(duration: 0.11)) {
                pose = .running(progress: progress, hop: -18 + CGFloat(step))
            }
            try? await Task.sleep(nanoseconds: 110_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.12)) {
                pose = .running(progress: progress, hop: 0)
            }
            try? await Task.sleep(nanoseconds: 120_000_000)
        }

        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.62)) {
            pose = DogPose(x: 0, y: 0, scale: 1, hop: 0, squashY: 0.88, lean: 0, opacity: 1)
        }
        try? await Task.sleep(nanoseconds: 180_000_000)
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.34, dampingFraction: 0.68)) {
            pose = .sitting
        }
    }

    @MainActor
    private func runOffstage() async {
        if pose.opacity < 0.05 {
            pose = .hiddenFar
            return
        }
        withAnimation(.easeIn(duration: 0.45)) {
            pose = .far
        }
        try? await Task.sleep(nanoseconds: 420_000_000)
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: 0.18)) {
            pose = .hiddenFar
        }
    }

    @MainActor
    private func celebrate() async {
        pose.opacity = 1
        pose.x = 0
        pose.scale = 1
        withAnimation(.spring(response: 0.38, dampingFraction: 0.55)) {
            pose.y = -10
            pose.squashY = 1.05
        }
        try? await Task.sleep(nanoseconds: 420_000_000)
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            pose = .sitting
        }
    }
}
