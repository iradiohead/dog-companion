import SpriteKit

enum PuppetPart: String, CaseIterable {
    case tail
    case backLeg
    case body
    case belly
    case frontLeg
    case farEar
    case nearEar
    case head
    case eye

    var fillName: String { "puppet_fill_\(rawValue)" }
    var lineName: String { "puppet_line_\(rawValue)" }

    var followsHead: Bool {
        self == .head || self == .nearEar || self == .farEar || self == .eye
    }

    var followsBody: Bool {
        self == .body || self == .belly
    }
}

enum PuppetCatalog {
    static let drawOrder: [PuppetPart] = [
        .tail, .backLeg, .body, .belly, .frontLeg, .farEar, .head, .nearEar, .eye
    ]

    static func texture(named name: String) -> SKTexture? {
        let texture = SKTexture(imageNamed: name)
        guard texture.size().width > 8, texture.size().height > 8 else {
            return nil
        }
        texture.filteringMode = .linear
        return texture
    }
}
