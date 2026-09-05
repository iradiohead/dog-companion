import Foundation
import SwiftUI
import SwiftData

enum CreationStep {
    case pickDog
    case generating
}

@Observable
@MainActor
final class CreationViewModel: ComicGenerationFlow {
    var step: CreationStep = .pickDog
    var sourceImage: UIImage?
    var selectedStyle: StyleTemplate = .default
    var generatedPortraitData: Data?
    var generatedCutoutData: Data?
    var selectedPalette: CoatPalette = .brown
    var companionName: String = ""
    var isGenerating = false
    var errorMessage: String?
    var availableDogs: [String] = []
    var selectedDogName: String?
    var currentStatusMessage = "正在读取狗狗资源…"
    private var resourceLoadPlan: ResourceDogLoadPlan?

    let mode: CreationMode = .current

    private let resourceService = ResourceDogService()
    private let generationService = GenerationService()

    var generatingTitle: String {
        switch mode {
        case .resourceCatalog:
            return "正在准备 \(selectedDogName ?? "你的狗狗")"
        case .photo:
            return "正在生成你的专注伙伴"
        }
    }

    var generatingStatusMessages: [String] {
        switch mode {
        case .resourceCatalog:
            return resourceLoadPlan?.messages ?? [
                ResourceDogLoadStatus.readingResources.message
            ]
        case .photo:
            return [
                "正在认出它的样子…",
                "正在画成你的狗…",
                "正在抠出透明图层…",
                "马上就好啦…"
            ]
        }
    }

    func refreshAvailableDogs() {
        availableDogs = resourceService.availableDogs()
        resourceService.preloadPreviews(for: availableDogs)
    }

    func previewImage(for dogName: String) async -> PlatformImage? {
        await resourceService.previewImage(for: dogName)
    }

    func selectDog(_ name: String) {
        selectedDogName = name
        companionName = name
        errorMessage = nil
        let plan = resourceService.loadPlan(for: name)
        resourceLoadPlan = plan
        currentStatusMessage = plan.messages.first ?? ResourceDogLoadStatus.readingResources.message
        step = .generating
    }

    func selectPhoto(_ image: UIImage) {
        guard mode == .photo else { return }
        sourceImage = image
        errorMessage = nil
        step = .generating
    }

    func startGeneration() async {
        switch mode {
        case .resourceCatalog:
            await generateFromResource()
        case .photo:
            await generateFromPhoto()
        }
    }

    func startGeneration(context: ModelContext, onSuccess: () -> Void = {}) async {
        await startGeneration()
        guard errorMessage == nil,
              generatedPortraitData != nil,
              generatedCutoutData != nil else { return }
        do {
            try saveCompanion(context: context)
            onSuccess()
        } catch {
            errorMessage = error.localizedDescription
            step = .pickDog
        }
    }

    func goBackToPhoto() {
        errorMessage = nil
        step = .pickDog
    }

    private func generateFromResource() async {
        guard let dogName = selectedDogName else {
            failGeneration("请先选择一只狗狗")
            return
        }

        await runGeneration {
            let assets = try await resourceService.loadAssets(for: dogName) { [self] status in
                self.currentStatusMessage = status.message
            }
            generatedPortraitData = assets.portraitData
            generatedCutoutData = assets.cutoutData
            selectedPalette = assets.coatPalette
            companionName = dogName
        }
    }

    private func generateFromPhoto() async {
        guard let image = sourceImage else {
            failGeneration("请先选择照片")
            return
        }

        await runGeneration {
            let result = try await generationService.generateCompanionAssets(from: image, style: selectedStyle)
            generatedPortraitData = result.comicPortraitData
            generatedCutoutData = result.cutoutData
            selectedPalette = result.coatPalette
            sourceImage = nil
        }
    }

    private func runGeneration(_ work: () async throws -> Void) async {
        isGenerating = true
        errorMessage = nil
        do {
            try await work()
        } catch {
            failGeneration(error.localizedDescription)
        }
        isGenerating = false
    }

    private func failGeneration(_ message: String) {
        errorMessage = message
        step = .pickDog
    }

    private func saveCompanion(context: ModelContext) throws {
        let trimmed = companionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw CreationError.missingName
        }
        guard let portraitData = generatedPortraitData,
              let cutoutData = generatedCutoutData else {
            throw CreationError.missingAssets
        }

        let existing = try context.fetch(FetchDescriptor<Companion>())
        existing.forEach { context.delete($0) }

        let companion = Companion(
            name: trimmed,
            comicPortraitData: portraitData,
            cutoutData: cutoutData,
            coatPalette: selectedPalette,
            styleTemplate: .default
        )
        context.insert(companion)
        try context.save()
        reset()
    }

    private func reset() {
        step = .pickDog
        sourceImage = nil
        generatedPortraitData = nil
        generatedCutoutData = nil
        selectedPalette = .brown
        companionName = ""
        selectedDogName = nil
        isGenerating = false
        errorMessage = nil
        resourceLoadPlan = nil
        currentStatusMessage = ResourceDogLoadStatus.readingResources.message
    }
}

enum CreationError: LocalizedError {
    case missingName
    case missingAssets

    var errorDescription: String? {
        switch self {
        case .missingName: return "缺少狗狗名字"
        case .missingAssets: return "缺少生成数据，请重新选择"
        }
    }
}
