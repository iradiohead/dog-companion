import Foundation
import SwiftUI
import SwiftData

enum CreationStep: Int, CaseIterable {
    case photo
    case generating
    case naming
}

@Observable
@MainActor
final class CreationViewModel: ComicGenerationFlow {
    var step: CreationStep = .photo
    var sourceImage: UIImage?
    var selectedStyle: StyleTemplate = .default
    var generatedPortraitData: Data?
    var generatedCutoutData: Data?
    var selectedPalette: CoatPalette = .brown
    var companionName: String = ""
    var isGenerating = false
    var errorMessage: String?

    private let generationService = GenerationService()

    func selectPhoto(_ image: UIImage) {
        sourceImage = image
        selectedStyle = .default
        errorMessage = nil
        step = .generating
    }

    func startGeneration() async {
        guard let image = sourceImage else {
            errorMessage = "请先选择照片"
            step = .photo
            return
        }
        let style = selectedStyle

        isGenerating = true
        errorMessage = nil

        do {
            let result = try await generationService.generateCompanionAssets(from: image, style: style)
            generatedPortraitData = result.comicPortraitData
            generatedCutoutData = result.cutoutData
            selectedPalette = result.coatPalette
            sourceImage = nil
            step = .naming
        } catch {
            errorMessage = error.localizedDescription
            step = .photo
        }

        isGenerating = false
    }

    func saveCompanion(context: ModelContext) throws {
        let trimmed = companionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "请给你的狗狗起个名字"
            return
        }
        guard let portraitData = generatedPortraitData,
              let cutoutData = generatedCutoutData else {
            errorMessage = "缺少生成数据，请重新开始"
            step = .photo
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
        step = .photo
        sourceImage = nil
        selectedStyle = .default
        generatedPortraitData = nil
        generatedCutoutData = nil
        selectedPalette = .brown
        companionName = ""
        isGenerating = false
        errorMessage = nil
    }

    func goBackToPhoto() {
        errorMessage = nil
        step = .photo
    }
}
