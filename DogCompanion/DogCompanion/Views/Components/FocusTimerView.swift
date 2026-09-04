import SwiftUI

struct FocusTimerView: View {
    let phase: FocusSessionPhase
    let formattedTime: String
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(formattedTime)
                .font(.system(size: 48, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())

            Text(statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                switch phase {
                case .idle, .completed:
                    Button(action: onStart) {
                        Label("开始专注", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                case .running:
                    Button(action: onPause) {
                        Label("暂停", systemImage: "pause.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button(role: .destructive, action: onCancel) {
                        Label("放弃", systemImage: "xmark")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                case .paused:
                    Button(action: onResume) {
                        Label("继续", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button(role: .destructive, action: onCancel) {
                        Label("放弃", systemImage: "xmark")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var statusText: String {
        switch phase {
        case .idle:
            return "狗狗在等你开始专注"
        case .running:
            return "狗狗正在陪你专注中…"
        case .paused:
            return "已暂停"
        case .completed:
            return "本次专注已完成"
        }
    }
}
