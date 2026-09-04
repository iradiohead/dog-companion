import Foundation

enum GiftUnlockPolicy {
    static func applyRewards(for sessionCount: Int, to companion: Companion) -> [String] {
        let newlyUnlocked = SceneCatalog.newlyUnlockedItems(afterSessionCount: sessionCount)
        for itemId in newlyUnlocked {
            companion.unlockItem(itemId)
        }
        return newlyUnlocked
    }

    static func giftTitle(for sessionCount: Int, unlockedItems: [String]) -> String {
        if unlockedItems.isEmpty {
            return SceneCatalog.giftName(for: sessionCount)
        }
        if let sceneId = unlockedItems.first(where: { id in SceneCatalog.scenes.contains { $0.id == id } }) {
            return "解锁场景：\(SceneCatalog.scene(for: sceneId).name)"
        }
        if let furnitureId = unlockedItems.first(where: { id in SceneCatalog.furniture.contains { $0.id == id } }) {
            return "解锁家具：\(SceneCatalog.furniture(for: furnitureId).name)"
        }
        return "收到礼物啦！"
    }
}
