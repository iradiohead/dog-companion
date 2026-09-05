import SwiftUI
import SwiftData

struct HomeView: View {
    @Bindable var companion: Companion
    var onBackToDogPicker: () -> Void
    @State private var viewModel = HomeViewModel()
    @State private var showRegeneration = false
    @State private var showScenePicker = false
    @State private var showSettings = false
    @State private var showStats = false
    @State private var showTimeline = false
    @State private var selectedTab: HomeTab = .decor
    @State private var sitImage: PlatformImage?
    @State private var runFrames: [PlatformImage] = []

    private var currentScene: SceneBackground {
        SceneCatalog.scene(for: companion.selectedSceneId)
    }

    var body: some View {
        ZStack {
            PaperBackgroundView()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                FocusTimerCenterView(
                    phase: viewModel.phase,
                    formattedTime: viewModel.formattedRemainingTime,
                    onStart: { viewModel.startFocus(with: companion) },
                    onCancel: { viewModel.cancelFocus() }
                )
                .padding(.top, 4)

                SceneView(
                    scene: currentScene,
                    sitImage: sitImage,
                    runFrames: runFrames,
                    palette: companion.coatPalette,
                    motionState: viewModel.motionState,
                    isFocusActive: viewModel.phase == .running,
                    onCompanionTap: {
                        viewModel.reactToTap()
                    }
                )
                .frame(maxHeight: .infinity)

                BottomNavBar(selectedTab: $selectedTab) { tab in
                    handleTab(tab)
                }
            }
        }
        .sheet(isPresented: $showRegeneration) {
            RegenerationFlowView(companion: companion)
        }
        .sheet(isPresented: $showScenePicker) {
            ScenePickerView(companion: companion)
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(companion: companion, showRegeneration: $showRegeneration)
        }
        .sheet(isPresented: $showStats) {
            StatsSheet(companion: companion)
        }
        .sheet(isPresented: $showTimeline) {
            TimelinePlaceholderSheet()
        }
        .sheet(isPresented: giftRevealBinding) {
            GiftRevealView(title: viewModel.pendingGiftTitle ?? "收到礼物啦！") {
                viewModel.dismissGift()
            }
        }
        .task(id: companion.persistentModelID) {
            await viewModel.refreshCutoutIfNeeded(for: companion)
            await refreshCompanionImages(for: companion)
        }
        .onChange(of: companion.cutoutData) { _, _ in
            Task { await refreshCompanionImages(for: companion) }
        }
        .onChange(of: companion.cutoutRunAData) { _, _ in
            Task { await refreshCompanionImages(for: companion) }
        }
        .onChange(of: companion.cutoutRunBData) { _, _ in
            Task { await refreshCompanionImages(for: companion) }
        }
        .navigationTitle("专注")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }

    private func refreshCompanionImages(for companion: Companion) async {
        let cutoutData = companion.cutoutData
        let opaqueData = await Task.detached(priority: .userInitiated) {
            guard let cutoutData else { return nil as Data? }
            if let opaque = try? CutoutImageProcessor.opaqueCutout(from: cutoutData) {
                return opaque
            }
            return cutoutData
        }.value

        sitImage = opaqueData.flatMap { PlatformImage.from(data: $0) }
        runFrames = companion.poseCutouts.runFrameImages()
    }

    private var topBar: some View {
        HStack {
            HandDrawnTextButton(title: "选狗狗", dotColor: .green) {
                reselectCompanion()
            }
            Spacer()
            HandDrawnTextButton(title: "设置", trailingIcon: "dog.fill") {
                showSettings = true
            }
        }
    }

    private func reselectCompanion() {
        if viewModel.isFocusActive {
            viewModel.cancelFocus()
        }
        onBackToDogPicker()
    }

    private func handleTab(_ tab: HomeTab) {
        switch tab {
        case .stats:
            showStats = true
        case .timeline:
            showTimeline = true
        case .decor:
            showScenePicker = true
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

private struct SettingsSheet: View {
    @Bindable var companion: Companion
    @Binding var showRegeneration: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("伙伴") {
                    LabeledContent("名字", value: companion.name)
                }
                if CreationMode.current == .photo {
                    Section {
                        Button("换造型") {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                showRegeneration = true
                            }
                        }
                        .disabled(!companion.canRegenerate)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

private struct StatsSheet: View {
    let companion: Companion
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("\(companion.completedFocusSessions)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(HandDrawnPalette.timerGreen)
                Text("次专注完成")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(HandDrawnPalette.ink)
                Spacer()
            }
            .padding(.top, 40)
            .frame(maxWidth: .infinity)
            .background(HandDrawnPalette.paperBase)
            .navigationTitle("统计")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct TimelinePlaceholderSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.largeTitle)
                    .foregroundStyle(HandDrawnPalette.inkLight)
                Text("时间轴即将推出")
                    .font(.headline)
                    .foregroundStyle(HandDrawnPalette.ink)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(HandDrawnPalette.paperBase)
            .navigationTitle("时间轴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    let companion = Companion(
        name: "旺财",
        comicPortraitData: nil,
        cutoutData: nil,
        styleTemplate: .default
    )
    return NavigationStack {
        HomeView(companion: companion, onBackToDogPicker: {})
    }
    .modelContainer(for: Companion.self, inMemory: true)
}
