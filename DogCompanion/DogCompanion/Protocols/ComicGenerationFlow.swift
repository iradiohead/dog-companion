import UIKit

@MainActor
protocol ComicGenerationFlow: AnyObject {
    var sourceImage: UIImage? { get set }
    var selectedStyle: StyleTemplate? { get set }
    var errorMessage: String? { get set }
    var isGenerating: Bool { get }
    func selectPhoto(_ image: UIImage)
    func selectStyle(_ style: StyleTemplate)
    func startGeneration() async
    func goBackToPhoto()
}
