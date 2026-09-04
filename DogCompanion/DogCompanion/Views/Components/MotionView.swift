import SwiftUI
import UIKit

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
    @State private var jumpOffset: CGFloat = 120
    @State private var reactionWiggle = false

    private var imageData: Data? {
        cutoutData ?? portraitData
    }

    var body: some View {
        Group {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(y: jumpOffset)
                    .rotationEffect(.degrees(rotation))
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                    .onTapGesture(perform: onTap)
            } else {
                Image(systemName: "dog.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
                    .padding(40)
            }
        }
        .frame(height: 200)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                breathing = true
            }
        }
        .onChange(of: motionState) { _, newValue in
            applyMotion(for: newValue)
        }
        .onAppear {
            applyMotion(for: motionState)
        }
    }

    private var scale: CGFloat {
        switch motionState {
        case .idle:
            return breathing ? 1.03 : 0.98
        case .jumpingIn:
            return 1.0
        case .reacting:
            return 1.06
        case .celebrating:
            return 1.08
        }
    }

    private var rotation: Double {
        motionState == .reacting && reactionWiggle ? 4 : 0
    }

    private func applyMotion(for state: CompanionMotionState) {
        switch state {
        case .idle:
            jumpOffset = 0
        case .jumpingIn:
            jumpOffset = 120
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
                jumpOffset = 0
            }
        case .reacting:
            reactionWiggle = true
            Task {
                try? await Task.sleep(nanoseconds: 200_000_000)
                reactionWiggle = false
            }
        case .celebrating:
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                jumpOffset = -12
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
