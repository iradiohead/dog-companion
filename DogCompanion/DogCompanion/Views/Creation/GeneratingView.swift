import SwiftUI

struct GeneratingView<VM>: View where VM: ComicGenerationFlow & Observable {
    @Bindable var viewModel: VM
    var title: String = "正在生成漫画形象"

    private let messages = [
        "正在分析毛色花纹…",
        "正在勾勒可爱线条…",
        "正在添加漫画魔法…",
        "马上就好啦…"
    ]

    @State private var messageIndex = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ProgressView()
                .controlSize(.large)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.bold())
                Text(messages[messageIndex])
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .animation(.easeInOut, value: messageIndex)
            }

            if let style = viewModel.selectedStyle {
                Label(style.displayName, systemImage: style.iconName)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.12), in: Capsule())
            }

            Spacer()
        }
        .padding()
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
                messageIndex = (messageIndex + 1) % messages.count
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .task {
            await viewModel.startGeneration()
        }
    }
}
