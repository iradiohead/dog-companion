import Foundation
import SwiftData

@Model
final class Companion {
    var name: String
    @Attribute(.externalStorage) var comicPortraitData: Data?
    @Attribute(.externalStorage) var cutoutData: Data?
    @Attribute(.externalStorage) var cutoutRunAData: Data?
    @Attribute(.externalStorage) var cutoutRunBData: Data?
    @Attribute(.externalStorage) var cutoutLandData: Data?
    var coatPaletteRaw: String = CoatPalette.brown.rawValue
    var styleTemplateRaw: String
    var createdAt: Date
    var regenerationCount: Int
    var selectedSceneId: String
    var selectedFurnitureId: String
    var completedFocusSessions: Int
    var unlockedItemIdsRaw: String

    init(
        name: String,
        comicPortraitData: Data?,
        cutoutData: Data? = nil,
        cutoutRunAData: Data? = nil,
        cutoutRunBData: Data? = nil,
        cutoutLandData: Data? = nil,
        coatPalette: CoatPalette = .brown,
        styleTemplate: StyleTemplate,
        createdAt: Date = .now,
        regenerationCount: Int = 0,
        selectedSceneId: String = SceneCatalog.defaultScene.id,
        selectedFurnitureId: String = SceneCatalog.defaultFurniture.id,
        completedFocusSessions: Int = 0,
        unlockedItemIds: [String] = SceneCatalog.starterUnlocks
    ) {
        self.name = name
        self.comicPortraitData = comicPortraitData
        self.cutoutData = cutoutData
        self.cutoutRunAData = cutoutRunAData
        self.cutoutRunBData = cutoutRunBData
        self.cutoutLandData = cutoutLandData
        self.coatPaletteRaw = coatPalette.rawValue
        self.styleTemplateRaw = styleTemplate.rawValue
        self.createdAt = createdAt
        self.regenerationCount = regenerationCount
        self.selectedSceneId = selectedSceneId
        self.selectedFurnitureId = selectedFurnitureId
        self.completedFocusSessions = completedFocusSessions
        self.unlockedItemIdsRaw = unlockedItemIds.joined(separator: ",")
    }

    var coatPalette: CoatPalette {
        get { CoatPalette(rawValue: coatPaletteRaw) ?? .brown }
        set { coatPaletteRaw = newValue.rawValue }
    }

    var poseCutouts: PoseCutoutSet {
        PoseCutoutSet(
            sit: cutoutData,
            runA: cutoutRunAData,
            runB: cutoutRunBData,
            land: cutoutLandData
        )
    }

    var styleTemplate: StyleTemplate {
        StyleTemplate(rawValue: styleTemplateRaw) ?? .anime
    }

    var canRegenerate: Bool {
        RegenerationPolicy.canRegenerate(usedCount: regenerationCount)
    }

    var remainingRegenerations: Int {
        RegenerationPolicy.remaining(usedCount: regenerationCount)
    }

    var unlockedItemIds: [String] {
        get {
            unlockedItemIdsRaw
                .split(separator: ",")
                .map(String.init)
                .filter { !$0.isEmpty }
        }
        set {
            unlockedItemIdsRaw = newValue.joined(separator: ",")
        }
    }

    func unlockItem(_ id: String) {
        var items = unlockedItemIds
        guard !items.contains(id) else { return }
        items.append(id)
        unlockedItemIds = items
    }

    func isUnlocked(_ id: String) -> Bool {
        unlockedItemIds.contains(id)
    }
}
