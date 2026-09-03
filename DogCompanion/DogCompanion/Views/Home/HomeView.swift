import SwiftUI
import SwiftData

struct HomeView: View {
    @Bindable var companion: Companion
    @State private var viewModel = HomeViewModel()
    @State private var showRegeneration = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ComicPortraitView(
                        portraitData: companion.comicPortraitData,
                        hunger: companion.hunger,
                        mood: companion.mood
                    )
                    .overlay(alignment: .bottom) {
                        actionOverlay
                    }

                    if companion.canRegenerate {
                        Text("还可以换 \(companion.remainingRegenerations) 次造型")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 16) {
                        VitalStatBar(
                            title: "饱食度",
                            value: companion.hunger,
                            color: .orange,
                            icon: "fork.knife"
                        )
                        VitalStatBar(
                            title: "心情",
                            value: companion.mood,
                            color: .pink,
                            icon: "heart.fill"
                        )
                    }
                    .padding(.horizontal)

                    HStack(spacing: 12) {
                        CareActionButton(title: "喂食", icon: "fork.knife", color: .orange) {
                            viewModel.feed(companion)
                        }
                        CareActionButton(title: "玩耍", icon: "tennisball.fill", color: .pink) {
                            viewModel.play(companion)
                        }
                        CareActionButton(title: "散步", icon: "figure.walk", color: .green) {
                            viewModel.walk(companion)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle(companion.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showRegeneration = true
                    } label: {
                        Label("换造型", systemImage: "paintbrush")
                    }
                    .disabled(!companion.canRegenerate)
                }
            }
            .sheet(isPresented: $showRegeneration) {
                RegenerationFlowView(companion: companion)
            }
            .onAppear {
                viewModel.refreshDecay(for: companion)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                viewModel.refreshDecay(for: companion)
            }
        }
    }

    @ViewBuilder
    private var actionOverlay: some View {
        if viewModel.showFeedAnimation {
            floatingBadge(text: "好吃！", icon: "fork.knife")
        } else if viewModel.showPlayAnimation {
            floatingBadge(text: "好开心！", icon: "tennisball.fill")
        } else if viewModel.showWalkAnimation {
            floatingBadge(text: "出去遛弯啦！", icon: "figure.walk")
        }
    }

    private func floatingBadge(text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.headline)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.bottom, 16)
            .transition(.scale.combined(with: .opacity))
            .animation(.spring, value: viewModel.showFeedAnimation)
    }
}

#Preview {
    let companion = Companion(name: "旺财", comicPortraitData: nil, styleTemplate: .anime)
    return HomeView(companion: companion)
        .modelContainer(for: Companion.self, inMemory: true)
}
