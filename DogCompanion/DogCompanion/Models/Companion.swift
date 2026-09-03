import Foundation
import SwiftData

@Model
final class Companion {
    var name: String
    @Attribute(.externalStorage) var comicPortraitData: Data?
    var hunger: Int
    var mood: Int
    var lastUpdated: Date
    var styleTemplateRaw: String
    var createdAt: Date
    var regenerationCount: Int

    init(
        name: String,
        comicPortraitData: Data?,
        hunger: Int = 80,
        mood: Int = 80,
        lastUpdated: Date = .now,
        styleTemplate: StyleTemplate,
        createdAt: Date = .now,
        regenerationCount: Int = 0
    ) {
        self.name = name
        self.comicPortraitData = comicPortraitData
        self.hunger = hunger
        self.mood = mood
        self.lastUpdated = lastUpdated
        self.styleTemplateRaw = styleTemplate.rawValue
        self.createdAt = createdAt
        self.regenerationCount = regenerationCount
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
}
