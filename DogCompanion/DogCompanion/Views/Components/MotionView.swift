import SwiftUI

enum CompanionMotionState {
    case idle
    case jumpingIn
    case reacting
    case celebrating
}

struct MotionView: View {
    let cutoutData: Data?
    let portraitData: Data?
    let motionState: CompanionMotionState
    let onTap: () -> Void

    @State private var breathing = false
    @State private var jumpOffset: CGFloat = 0
    @State private var reactionWiggle = false

    /// Never fall back to the unmatted comic portrait — that is what flashes a paper background while animating.
    private var imageData: Data? {
        cutoutData
    }

    var body: some View {
        Group {
            if let imageData, let uiImage = PlatformImage.from(data: imageData) {
                Image(platformImage: uiImage)
                    .interpolation(.high)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(x: squashX, y: squashY, anchor: .bottom)
                    .offset(y: jumpOffset + breathOffset)
                    .rotationEffect(.degrees(rotation), anchor: .bottom)
                    .compositingGroup()
                    .shadow(color: .black.opacity(0.12), radius: 4, y: 3)
                    .onTapGesture(perform: onTap)
            } else {
                Image(systemName: "dog.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
                    .padding(36)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .clipped()
        .onAppear {
            applyMotion(for: motionState)
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                breathing = true
            }
        }
        .onChange(of: motionState) { _, newValue in
            applyMotion(for: newValue)
        }
    }

    /// Idle uses a tiny vertical bob, not uniform zoom — zooming scales leftover paper with the dog.
    private var breathOffset: CGFloat {
        motionState == .idle && breathing ? -3 : 0
    }

    private var squashY: CGFloat {
        switch motionState {
        case .idle, .jumpingIn:
            return 1
        case .reacting:
            return 1.03
        case .celebrating:
            return 1.04
        }
    }

    private var squashX: CGFloat {
        switch motionState {
        case .reacting:
            return 0.98
        default:
            return 1
        }
    }

    private var rotation: Double {
        motionState == .reacting && reactionWiggle ? 3 : 0
    }

    private func applyMotion(for state: CompanionMotionState) {
        switch state {
        case .idle:
            withAnimation(.easeOut(duration: 0.25)) {
                jumpOffset = 0
            }
        case .jumpingIn:
            jumpOffset = 28
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                jumpOffset = 0
            }
        case .reacting:
            reactionWiggle = true
            Task {
                try? await Task.sleep(nanoseconds: 200_000_000)
                reactionWiggle = false
            }
        case .celebrating:
            withAnimation(.spring(response: 0.45, dampingFraction: 0.62)) {
                jumpOffset = -8
            }
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                withAnimation(.spring) {
                    jumpOffset = 0
                }
            }
        }
    }
}
