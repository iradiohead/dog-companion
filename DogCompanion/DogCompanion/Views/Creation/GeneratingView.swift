import SwiftUI
import Observation

struct GeneratingView<VM>: View where VM: ComicGenerationFlow & Observable {
    @Bindable var viewModel: VM
    var title: String = "正在生成你的专注伙伴"
    var statusMessages: [String]?
    var liveStatusMessage: String? = nil
    var showsStyleBadge: Bool = true
    var performGeneration: (() async -> Void)?

    private var messages: [String] {
        statusMessages ?? [
            "正在认出它的样子…",
            "正在画成你的狗…",
            "正在抠出透明图层…",
            "马上就好啦…"
        ]
    }

    @State private var messageIndex = 0
    @State private var timer: Timer?

    private var displayedMessage: String {
        if let liveStatusMessage, !liveStatusMessage.isEmpty {
            return liveStatusMessage
        }
        guard !messages.isEmpty else { return "" }
        return messages[messageIndex % messages.count]
    }

    var body: some View {
        ZStack {
            PaperBackgroundView()

            VStack(spacing: 32) {
                Spacer()

                ProgressView()
                    .controlSize(.large)

                VStack(spacing: 8) {
                    Text(title)
                        .font(.title2.bold())
                    Text(displayedMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .animation(.easeInOut, value: displayedMessage)
                }

                if showsStyleBadge {
                    Label(StyleTemplate.default.displayName, systemImage: StyleTemplate.default.iconName)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                }

                Spacer()
            }
            .padding()
        }
        .onAppear {
            guard liveStatusMessage == nil, messages.count > 1 else { return }
            timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
                messageIndex = (messageIndex + 1) % messages.count
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .task {
            if let performGeneration {
                await performGeneration()
            } else {
                await viewModel.startGeneration()
            }
        }
    }
}
