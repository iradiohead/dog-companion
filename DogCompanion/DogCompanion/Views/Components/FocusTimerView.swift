import SwiftUI

struct FocusTimerView: View {
    let phase: FocusSessionPhase
    let formattedTime: String
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HandDrawnCard {
            VStack(spacing: 14) {
                Text(formattedTime)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(HandDrawnPalette.ink)
                    .contentTransition(.numericText())

                Text(statusText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(HandDrawnPalette.inkLight)

                controlButtons
            }
        }
    }

    @ViewBuilder
    private var controlButtons: some View {
        switch phase {
        case .idle, .completed:
            HandDrawnActionButton(title: "开始专注", icon: "play.fill", action: onStart)

        case .running:
            HStack(spacing: 10) {
                HandDrawnActionButton(title: "暂停", icon: "pause.fill", tint: Color(red: 0.65, green: 0.58, blue: 0.50), action: onPause)
                HandDrawnActionButton(
                    title: "放弃",
                    icon: "xmark",
                    tint: Color(red: 0.78, green: 0.48, blue: 0.42),
                    isPrimary: false,
                    action: onCancel
                )
            }

        case .paused:
            HStack(spacing: 10) {
                HandDrawnActionButton(title: "继续", icon: "play.fill", action: onResume)
                HandDrawnActionButton(
                    title: "放弃",
                    icon: "xmark",
                    tint: Color(red: 0.78, green: 0.48, blue: 0.42),
                    isPrimary: false,
                    action: onCancel
                )
            }
        }
    }

    private var statusText: String {
        switch phase {
        case .idle:
            return "狗狗在桌边等你开始专注"
        case .running:
            return "狗狗正在安静地陪你…"
        case .paused:
            return "专注已暂停"
        case .completed:
            return "本次专注完成啦"
        }
    }
}
