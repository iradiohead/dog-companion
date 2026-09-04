import SwiftUI
import SwiftData

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
        ZStack {
            SceneView(
                scene: currentScene,
                furniture: currentFurniture,
                cutoutData: companion.cutoutData,
                portraitData: companion.comicPortraitData,
                motionState: viewModel.motionState,
                isFocusActive: viewModel.phase == .running,
                onCompanionTap: {
                    viewModel.reactToTap()
                }
            )

            VStack {
                topBar
                Spacer()
                bottomPanel
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .background(HandDrawnPalette.cream)
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

    private var topBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(companion.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(HandDrawnPalette.ink)
                Text("已完成 \(companion.completedFocusSessions) 次专注")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(HandDrawnPalette.inkLight)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                Capsule(style: .continuous)
                    .fill(HandDrawnPalette.paper.opacity(0.85))
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(HandDrawnPalette.ink.opacity(0.25), lineWidth: 1.5)
                    }
            }

            Spacer()

            HStack(spacing: 10) {
                HandDrawnIconButton(icon: "paintpalette", label: "装扮") {
                    showScenePicker = true
                }
                HandDrawnIconButton(icon: "paintbrush", label: "换造型") {
                    showRegeneration = true
                }
                .opacity(companion.canRegenerate ? 1 : 0.45)
                .disabled(!companion.canRegenerate)
            }
        }
    }

    private var bottomPanel: some View {
        VStack(spacing: 10) {
            FocusTimerView(
                phase: viewModel.phase,
                formattedTime: viewModel.formattedRemainingTime,
                onStart: { viewModel.startFocus(with: companion) },
                onPause: { viewModel.pauseFocus() },
                onResume: { viewModel.resumeFocus(with: companion) },
                onCancel: { viewModel.cancelFocus() }
            )

            if companion.canRegenerate {
                Text("还可以换 \(companion.remainingRegenerations) 次造型")
                    .font(.caption2)
                    .foregroundStyle(HandDrawnPalette.inkLight.opacity(0.9))
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
