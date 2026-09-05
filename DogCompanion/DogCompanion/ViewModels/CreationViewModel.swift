import Foundation
import SwiftUI
import SwiftData

enum CreationStep: Int, CaseIterable {
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

    private let resourceLoader = ResourceDogLoader()

    func refreshAvailableDogs() {
        availableDogs = ResourceDogCatalog().availableDogNames()
    }

    func selectDog(_ name: String) {
        selectedDogName = name
        companionName = name
        sourceImage = nil
        selectedStyle = .default
        errorMessage = nil
        step = .generating
    }

    func selectPhoto(_ image: UIImage) {
        guard !CompanionCreationConfig.useResourceCatalog else { return }
        sourceImage = image
        selectedStyle = .default
        errorMessage = nil
        step = .generating
    }

    func startGeneration() async {
        if CompanionCreationConfig.useResourceCatalog {
            await startResourceGeneration()
        } else {
            await startPhotoGeneration()
        }
    }

    func startGeneration(context: ModelContext) async {
        await startGeneration()
        guard errorMessage == nil,
              generatedPortraitData != nil,
              generatedCutoutData != nil else { return }
        do {
            try saveCompanion(context: context)
        } catch {
            errorMessage = error.localizedDescription
            step = .pickDog
        }
    }

    private func startResourceGeneration() async {
        guard let dogName = selectedDogName else {
            errorMessage = "请先选择一只狗狗"
            step = .pickDog
            return
        }

        isGenerating = true
        errorMessage = nil

        do {
            let assets = try await resourceLoader.loadAssets(for: dogName)
            generatedPortraitData = assets.portraitData
            generatedCutoutData = assets.cutoutData
            selectedPalette = assets.coatPalette
            companionName = dogName
        } catch {
            errorMessage = error.localizedDescription
            step = .pickDog
        }

        isGenerating = false
    }

    private func startPhotoGeneration() async {
        guard let image = sourceImage else {
            errorMessage = "请先选择照片"
            step = .pickDog
            return
        }

        let generationService = GenerationService()
        isGenerating = true
        errorMessage = nil

        do {
            let result = try await generationService.generateCompanionAssets(from: image, style: selectedStyle)
            generatedPortraitData = result.comicPortraitData
            generatedCutoutData = result.cutoutData
            selectedPalette = result.coatPalette
            sourceImage = nil
        } catch {
            errorMessage = error.localizedDescription
            step = .pickDog
        }

        isGenerating = false
    }

    func saveCompanion(context: ModelContext) throws {
        let trimmed = companionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "缺少狗狗名字"
            return
        }
        guard let portraitData = generatedPortraitData,
              let cutoutData = generatedCutoutData else {
            errorMessage = "缺少生成数据，请重新选择"
            step = .pickDog
            return
        }

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

    func reset() {
        step = .pickDog
        sourceImage = nil
        selectedStyle = .default
        generatedPortraitData = nil
        generatedCutoutData = nil
        selectedPalette = .brown
        companionName = ""
        selectedDogName = nil
        isGenerating = false
        errorMessage = nil
    }

    func goBackToPhoto() {
        errorMessage = nil
        step = .pickDog
    }
}
