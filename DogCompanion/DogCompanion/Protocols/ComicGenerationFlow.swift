import UIKit

@MainActor
protocol ComicGenerationFlow: AnyObject {
    var sourceImage: UIImage? { get set }
    var selectedStyle: StyleTemplate { get }
    var errorMessage: String? { get set }
    var isGenerating: Bool { get }
    func selectPhoto(_ image: UIImage)
    func startGeneration() async
    func goBackToPhoto()
}
