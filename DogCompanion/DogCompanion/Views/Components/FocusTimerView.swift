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
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(HandDrawnPalette.timerGreen)
                .overlay {
                    Text(formattedTime)
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.clear)
                        .overlay {
                            Text(formattedTime)
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(HandDrawnPalette.timerGreenStroke.opacity(0.35))
                                .offset(x: 1, y: 1)
                        }
                }
                .contentTransition(.numericText())

            HStack(spacing: 6) {
                Image(systemName: "pencil")
                    .font(.caption.weight(.bold))
                Text("专注")
                    .font(.title3.weight(.semibold))
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
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    HandDrawnPalette.startBlue.opacity(0.85),
                                    HandDrawnPalette.startBlue.opacity(0.45),
                                    Color(red: 0.62, green: 0.82, blue: 0.96).opacity(0.35)
                                ],
                                center: UnitPoint(x: 0.35, y: 0.3),
                                startRadius: 8,
                                endRadius: 70
                            )
                        )
                        .frame(width: 124, height: 54)
                        .overlay {
                            Ellipse()
                                .strokeBorder(
                                    HandDrawnPalette.ink.opacity(0.15),
                                    style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6, 4])
                                )
                        }
                        .paperTextured(opacity: 0.15)
                    Text("开始")
                        .font(.title2.weight(.bold))
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
                    Ellipse()
                        .fill(HandDrawnPalette.startBlue.opacity(0.7))
                }
        }
        .buttonStyle(.plain)
    }
}
