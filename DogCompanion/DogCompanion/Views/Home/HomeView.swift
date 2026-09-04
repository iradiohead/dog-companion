import SwiftUI
import SwiftData
import UIKit

struct HomeView: View {
    @Bindable var companion: Companion
    @State private var viewModel = HomeViewModel()
    @State private var showRegeneration = false
    @State private var showScenePicker = false

    private var currentScene: SceneBackground {
        SceneCatalog.scene(for: companion.selectedSceneId)
    }

    private var currentFurniture: FurnitureItem {
        SceneCatalog.furniture(for: companion.selectedFurnitureId)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    SceneView(
                        scene: currentScene,
                        furniture: currentFurniture,
                        cutoutData: companion.cutoutData,
                        portraitData: companion.comicPortraitData,
                        motionState: viewModel.motionState,
                        onCompanionTap: {
                            viewModel.reactToTap()
                        }
                    )
                    .padding(.horizontal)

                    FocusTimerView(
                        phase: viewModel.phase,
                        formattedTime: viewModel.formattedRemainingTime,
                        onStart: { viewModel.startFocus(with: companion) },
                        onPause: { viewModel.pauseFocus() },
                        onResume: { viewModel.resumeFocus(with: companion) },
                        onCancel: { viewModel.cancelFocus() }
                    )
                    .padding(.horizontal)

                    HStack {
                        Label("已完成 \(companion.completedFocusSessions) 次专注", systemImage: "checkmark.seal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if companion.canRegenerate {
                            Text("还可换 \(companion.remainingRegenerations) 次造型")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle(companion.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showScenePicker = true
                    } label: {
                        Label("装扮", systemImage: "paintpalette")
                    }
                }
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
            .sheet(isPresented: $showScenePicker) {
                ScenePickerView(companion: companion)
            }
            .sheet(isPresented: giftRevealBinding) {
                GiftRevealView(title: viewModel.pendingGiftTitle ?? "收到礼物啦！") {
                    viewModel.dismissGift()
                }
            }
        }
    }

    private var giftRevealBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showGiftReveal },
            set: { isPresented in
                if !isPresented {
                    viewModel.dismissGift()
                }
            }
        )
    }
}

#Preview {
    let companion = Companion(
        name: "旺财",
        comicPortraitData: nil,
        cutoutData: nil,
        styleTemplate: .anime
    )
    return HomeView(companion: companion)
        .modelContainer(for: Companion.self, inMemory: true)
}
