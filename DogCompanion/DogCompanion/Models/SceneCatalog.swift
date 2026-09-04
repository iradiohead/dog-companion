import SwiftUI

struct SceneBackground: Identifiable, Hashable {
    let id: String
    let name: String
    let topColor: Color
    let bottomColor: Color
    let accentColor: Color
    let unlockAfterSessions: Int

    var isDefaultUnlocked: Bool { unlockAfterSessions == 0 }
}

struct FurnitureItem: Identifiable, Hashable {
    let id: String
    let name: String
    let iconName: String
    let tint: Color
    let unlockAfterSessions: Int

    var isDefaultUnlocked: Bool { unlockAfterSessions == 0 }
}

enum SceneCatalog {
    static let defaultScene = scenes[0]
    static let defaultFurniture = furniture[0]

    static let starterUnlocks: [String] = [
        defaultScene.id,
        defaultFurniture.id
    ]

    static let scenes: [SceneBackground] = [
        SceneBackground(
            id: "warm_living",
            name: "温暖客厅",
            topColor: Color(red: 0.96, green: 0.90, blue: 0.82),
            bottomColor: Color(red: 0.88, green: 0.78, blue: 0.68),
            accentColor: Color(red: 0.72, green: 0.55, blue: 0.42),
            unlockAfterSessions: 0
        ),
        SceneBackground(
            id: "cozy_study",
            name: "安静书房",
            topColor: Color(red: 0.85, green: 0.88, blue: 0.94),
            bottomColor: Color(red: 0.70, green: 0.76, blue: 0.86),
            accentColor: Color(red: 0.45, green: 0.52, blue: 0.64),
            unlockAfterSessions: 1
        ),
        SceneBackground(
            id: "sunny_corner",
            name: "阳光角落",
            topColor: Color(red: 0.98, green: 0.94, blue: 0.82),
            bottomColor: Color(red: 0.92, green: 0.84, blue: 0.66),
            accentColor: Color(red: 0.82, green: 0.68, blue: 0.38),
            unlockAfterSessions: 3
        )
    ]

    static let furniture: [FurnitureItem] = [
        FurnitureItem(
            id: "mat_cream",
            name: "奶油小垫",
            iconName: "rectangle.roundedbottom",
            tint: Color(red: 0.95, green: 0.90, blue: 0.82),
            unlockAfterSessions: 0
        ),
        FurnitureItem(
            id: "cushion_blue",
            name: "蓝色圆垫",
            iconName: "square.fill",
            tint: Color(red: 0.55, green: 0.72, blue: 0.88),
            unlockAfterSessions: 2
        ),
        FurnitureItem(
            id: "bone_pillow",
            name: "暖棕软垫",
            iconName: "oval.fill",
            tint: Color(red: 0.92, green: 0.82, blue: 0.70),
            unlockAfterSessions: 4
        )
    ]

    static func scene(for id: String) -> SceneBackground {
        scenes.first { $0.id == id } ?? defaultScene
    }

    static func furniture(for id: String) -> FurnitureItem {
        furniture.first { $0.id == id } ?? defaultFurniture
    }

    static func newlyUnlockedItems(afterSessionCount count: Int) -> [String] {
        let sceneIds = scenes.filter { $0.unlockAfterSessions == count }.map(\.id)
        let furnitureIds = furniture.filter { $0.unlockAfterSessions == count }.map(\.id)
        return sceneIds + furnitureIds
    }

    static func giftName(for sessionCount: Int) -> String {
        let unlocked = newlyUnlockedItems(afterSessionCount: sessionCount)
        if let sceneId = unlocked.first(where: { id in scenes.contains { $0.id == id } }) {
            return scene(for: sceneId).name
        }
        if let furnitureId = unlocked.first(where: { id in furniture.contains { $0.id == id } }) {
            return furniture(for: furnitureId).name
        }
        return "小零食"
    }
}
