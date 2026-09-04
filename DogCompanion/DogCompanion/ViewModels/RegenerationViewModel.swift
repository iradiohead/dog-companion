import Foundation
import SwiftUI

enum RegenerationStep: Int, CaseIterable {
    case photo
    case style
    case generating
}

@Observable
@MainActor
final class RegenerationViewModel: ComicGenerationFlow {
    var step: RegenerationStep = .photo
    var sourceImage: UIImage?
    var selectedStyle: StyleTemplate?
    var errorMessage: String?
    var isGenerating = false
    var isComplete = false

    private let companion: Companion
    private let generationService = GenerationService()
    private var generatedPortraitData: Data?
    private var generatedPalette: CoatPalette = .brown

    init(companion: Companion) {
        self.companion = companion
        self.selectedStyle = companion.styleTemplate
    }

    var canRegenerate: Bool {
        companion.canRegenerate
    }

    var remainingRegenerations: Int {
        companion.remainingRegenerations
    }

    func selectPhoto(_ image: UIImage) {
        sourceImage = image
        errorMessage = nil
        step = .style
    }

    func selectStyle(_ style: StyleTemplate) {
        selectedStyle = style
        errorMessage = nil
        step = .generating
    }

    func startGeneration() async {
        guard canRegenerate else {
            errorMessage = "重新生成次数已用完"
            return
        }

        guard let image = sourceImage, let style = selectedStyle else {
            errorMessage = "请先选择照片和风格"
            step = .photo
            return
        }

        isGenerating = true
        errorMessage = nil

        do {
            let result = try await generationService.generateCompanionAssets(from: image, style: style)
            generatedPortraitData = result.comicPortraitData
            generatedPalette = result.coatPalette
            sourceImage = nil
            applyRegeneration()
            isComplete = true
        } catch {
            errorMessage = error.localizedDescription
            step = .photo
        }

        isGenerating = false
    }

    func goBackToPhoto() {
        errorMessage = nil
        step = .photo
    }

    private func applyRegeneration() {
        guard let portraitData = generatedPortraitData,
              let style = selectedStyle else { return }
        companion.comicPortraitData = portraitData
        companion.coatPalette = generatedPalette
        companion.cutoutData = nil
        companion.cutoutRunAData = nil
        companion.cutoutRunBData = nil
        companion.cutoutLandData = nil
        companion.styleTemplateRaw = style.rawValue
        companion.regenerationCount += 1
    }
}
