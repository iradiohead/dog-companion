import Foundation
import UIKit

struct ResourceDogAssets {
    let portraitData: Data
    let cutoutData: Data
    let coatPalette: CoatPalette
}

struct ResourceDogLoader {
    var catalog = ResourceDogCatalog()
    var generationService = GenerationService()
    var mattingService = MattingService()

    func loadAssets(for dogName: String) async throws -> ResourceDogAssets {
        let contents = try catalog.folderContents(for: dogName)

        let portraitData: Data
        if let handDrawnURL = contents.handDrawnURL {
            portraitData = try Data(contentsOf: handDrawnURL)
        } else {
            guard let originalURL = contents.originalURL else {
                throw ResourceDogError.missingOriginal(dogName)
            }
            guard let originalImage = UIImage(contentsOfFile: originalURL.path) else {
                throw ResourceDogError.invalidImage(dogName)
            }
            portraitData = try await generationService.generateComicPortrait(
                from: originalImage,
                style: .default,
                pose: .sit
            )
        }

        guard let portraitImage = UIImage(data: portraitData) else {
            throw ResourceDogError.invalidImage(dogName)
        }

        let cutoutData: Data
        if let foregroundURL = contents.foregroundURL {
            cutoutData = try Data(contentsOf: foregroundURL)
        } else {
            cutoutData = try await mattingService.extractCutout(from: portraitImage, pose: .sit)
        }

        return ResourceDogAssets(
            portraitData: portraitData,
            cutoutData: cutoutData,
            coatPalette: CoatSampler.snap(from: portraitImage)
        )
    }
}
