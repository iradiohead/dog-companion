import SwiftUI

struct FocusTimerCenterView: View {
    let phase: FocusSessionPhase
    let formattedTime: String
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(formattedTime)
                .font(HandDrawnFont.marker(64, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(HandDrawnPalette.timerGreen)
                .shadow(color: HandDrawnPalette.timerGreenStroke.opacity(0.35), radius: 0, x: 1.2, y: 1.4)
                .contentTransition(.numericText())

            HStack(spacing: 6) {
                Image(systemName: "pencil")
                    .font(.caption.weight(.bold))
                Text("专注")
                    .font(HandDrawnFont.brush(22))
            }
            .foregroundStyle(HandDrawnPalette.ink)

            primaryControl
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var primaryControl: some View {
        switch phase {
        case .idle, .completed:
            Button(action: onStart) {
                ZStack {
                    WobblyEllipse(wobble: 2.8, seed: 70)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.70, green: 0.86, blue: 0.96),
                                    HandDrawnPalette.startBlue,
                                    Color(red: 0.58, green: 0.78, blue: 0.92).opacity(0.5)
                                ],
                                center: UnitPoint(x: 0.32, y: 0.28),
                                startRadius: 6,
                                endRadius: 72
                            )
                        )
                        .overlay {
                            PencilHatchOverlay(opacity: 0.08, density: 10, angle: -16)
                                .clipShape(WobblyEllipse(wobble: 2.8, seed: 70))
                        }
                        .overlay {
                            ZStack {
                                WobblyEllipse(wobble: 3, seed: 71)
                                    .stroke(HandDrawnPalette.ink.opacity(0.18), lineWidth: 2.6)
                                WobblyEllipse(wobble: 2.4, seed: 72)
                                    .stroke(HandDrawnPalette.ink.opacity(0.32), lineWidth: 1.4)
                            }
                        }
                        .frame(width: 128, height: 56)
                    Text("开始")
                        .font(HandDrawnFont.brush(26))
                        .foregroundStyle(HandDrawnPalette.ink)
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 4)

        case .running:
            HStack(spacing: 24) {
                controlChip(title: "暂停", action: onPause)
                controlChip(title: "放弃", action: onCancel)
            }
            .padding(.top, 8)

        case .paused:
            HStack(spacing: 24) {
                controlChip(title: "继续", action: onResume)
                controlChip(title: "放弃", action: onCancel)
            }
            .padding(.top, 8)
        }
    }

    private func controlChip(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(HandDrawnPalette.ink)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background {
                    WobblyEllipse(wobble: 2.2, seed: 80)
                        .fill(HandDrawnPalette.startBlue.opacity(0.75))
                }
        }
        .buttonStyle(.plain)
    }
}
