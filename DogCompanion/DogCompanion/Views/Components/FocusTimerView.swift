import SwiftUI

struct FocusTimerCenterView: View {
    let phase: FocusSessionPhase
    let formattedTime: String
    let onStart: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HandDrawnTimerText(time: formattedTime)

            HStack(spacing: 6) {
                Image(systemName: "pencil")
                    .font(.caption.weight(.bold))
                Text("专注")
                    .font(HandDrawnFont.brush(22))
            }
            .foregroundStyle(HandDrawnPalette.ink)

            primaryControl
        }
        .padding(.top, 4)
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

        case .running, .paused:
            controlChip(title: "放弃", action: onCancel)
                .padding(.top, 8)
        }
    }

    private func controlChip(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(HandDrawnFont.brush(22))
                .foregroundStyle(HandDrawnPalette.ink)
                .padding(.horizontal, 22)
                .padding(.vertical, 8)
                .background {
                    WobblyEllipse(wobble: 2.2, seed: 80)
                        .fill(HandDrawnPalette.startBlue.opacity(0.75))
                }
        }
        .buttonStyle(.plain)
    }
}

struct HandDrawnTimerText: View {
    let time: String

    var body: some View {
        HStack(alignment: .center, spacing: 1) {
            ForEach(Array(time.enumerated()), id: \.offset) { index, character in
                let wobble = HandDrawnTexture.unit(index + 3, 19)
                Text(String(character))
                    .font(HandDrawnFont.marker(58))
                    .foregroundStyle(HandDrawnPalette.timerGreen)
                    .shadow(
                        color: HandDrawnPalette.timerGreenStroke.opacity(0.55),
                        radius: 0,
                        x: 1.4,
                        y: 1.8
                    )
                    .shadow(
                        color: HandDrawnPalette.ink.opacity(0.12),
                        radius: 0,
                        x: 0.6,
                        y: 0.8
                    )
                    .rotationEffect(.degrees(Double(wobble - 0.48) * 5.2))
                    .offset(
                        x: (wobble - 0.5) * 1.6,
                        y: (wobble - 0.42) * 4.2
                    )
                    .padding(.horizontal, character == ":" ? -1 : 0)
            }
        }
    }
}
