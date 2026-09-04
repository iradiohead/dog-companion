import SwiftUI
import SpriteKit
import UIKit

struct CompanionRigView: UIViewRepresentable {
    var image: PlatformImage? = nil
    var palette: CoatPalette = .brown
    var state: CompanionRigState
    var elapsed: TimeInterval
    var isPaused: Bool
    var motion: CompanionMotionState? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.allowsTransparency = true
        view.backgroundColor = .clear
        view.isAsynchronous = true
        view.ignoresSiblingOrder = true
        view.isUserInteractionEnabled = false
        view.preferredFramesPerSecond = 60
        view.layer.isOpaque = false
        view.clipsToBounds = false
        view.layer.masksToBounds = false

        let scene = context.coordinator.scene
        scene.image = image
        scene.palette = palette
        scene.rigState = state
        scene.elapsed = elapsed
        scene.motion = motion
        view.presentScene(scene)
        view.isPaused = isPaused
        return view
    }

    func updateUIView(_ view: SKView, context: Context) {
        context.coordinator.scene.image = image
        context.coordinator.scene.palette = palette
        context.coordinator.scene.rigState = state
        context.coordinator.scene.elapsed = elapsed
        context.coordinator.scene.motion = motion
        context.coordinator.scene.applyCurrent()
        if view.isPaused != isPaused {
            view.isPaused = isPaused
        }
    }

    final class Coordinator {
        let scene = CompanionRigScene()
    }
}

final class CompanionRigScene: SKScene {
    private var root = SKNode()
    private var cutoutNodes: [CompanionPart: SKSpriteNode] = [:]
    private var fillNodes: [PuppetPart: SKSpriteNode] = [:]
    private var lineNodes: [PuppetPart: SKSpriteNode] = [:]
    private var spotNode: SKSpriteNode?
    private var fittedSize = CGSize(width: 150, height: 168)
    private let headAnchorY: CGFloat = 0.52
    private var lastImage: PlatformImage?
    private var lastPalette: CoatPalette?
    private var cutoutTailOnLeft = true

    var rigState: CompanionRigState = .sitting
    var elapsed: TimeInterval = 0
    var motion: CompanionMotionState?
    var image: PlatformImage? {
        didSet {
            guard !Self.isSameImage(image, lastImage) else { return }
            lastImage = image
            rebuild()
        }
    }

    var palette: CoatPalette = .brown {
        didSet {
            guard palette != lastPalette else { return }
            lastPalette = palette
            applyPalette()
        }
    }

    private var usesOwnerCutout: Bool { image != nil }

    override init() {
        super.init(size: CGSize(width: 150, height: 168))
        backgroundColor = .clear
        scaleMode = .resizeFill
        anchorPoint = .zero
        addChild(root)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        rebuild()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        layoutParts()
        applyCurrent()
    }

    override func update(_: TimeInterval) {
        applyCurrent()
    }

    func applyCurrent() {
        if let motion {
            apply(CompanionRigMotion.transform(motion: motion, elapsed: elapsed))
        } else {
            apply(CompanionRigMotion.transform(state: rigState, time: elapsed))
        }
    }

    private func rebuild() {
        root.removeAllChildren()
        cutoutNodes.removeAll()
        fillNodes.removeAll()
        lineNodes.removeAll()
        spotNode = nil

        if let image {
            buildCutout(from: image)
        } else {
            cutoutTailOnLeft = true
            buildSharedPuppet()
        }
        layoutParts()
        applyCurrent()
    }

    private func buildCutout(from image: PlatformImage) {
        let layers = CompanionLayerSlicer.slice(image)
        let drawOrder: [CompanionPart] = [.tail, .backLeg, .body, .frontLeg, .head]
        if let layers {
            cutoutTailOnLeft = layers.tailOnLeft
            for part in drawOrder {
                guard let partImage = layers.image(for: part) else { continue }
                let node = makeCutoutSprite(from: partImage, part: part)
                node.zPosition = CGFloat(drawOrder.firstIndex(of: part) ?? 0)
                root.addChild(node)
                cutoutNodes[part] = node
            }
        } else {
            cutoutTailOnLeft = true
            let node = makeCutoutSprite(from: image, part: .body)
            node.zPosition = 2
            root.addChild(node)
            cutoutNodes[.body] = node
        }
    }

    private func buildSharedPuppet() {
        for (index, part) in PuppetCatalog.drawOrder.enumerated() {
            let z = CGFloat(index)
            if let fill = makePuppetSprite(named: part.fillName, part: part, blend: true) {
                fill.zPosition = z
                root.addChild(fill)
                fillNodes[part] = fill
            }
            if let line = makePuppetSprite(named: part.lineName, part: part, blend: false) {
                line.zPosition = z + 0.4
                root.addChild(line)
                lineNodes[part] = line
            }
        }
        if let spots = makePuppetSprite(named: "puppet_spots", part: .body, blend: true) {
            spots.zPosition = 2.2
            root.addChild(spots)
            spotNode = spots
        }
        applyPalette()
    }

    private func makeCutoutSprite(from image: UIImage, part: CompanionPart) -> SKSpriteNode {
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        let node = SKSpriteNode(texture: texture)
        node.anchorPoint = cutoutAnchor(for: part)
        return node
    }

    private func makePuppetSprite(named name: String, part: PuppetPart, blend: Bool) -> SKSpriteNode? {
        guard let texture = PuppetCatalog.texture(named: name) else { return nil }
        let node = SKSpriteNode(texture: texture)
        node.colorBlendFactor = blend ? 1 : 0
        node.anchorPoint = puppetAnchor(for: part)
        return node
    }

    private func layoutParts() {
        guard size.width > 1, size.height > 1 else { return }
        root.position = CGPoint(x: size.width / 2, y: 0)
        root.zRotation = 0
        if usesOwnerCutout, let image {
            let imageSize = image.size
            guard imageSize.width > 0, imageSize.height > 0 else { return }
            let fitWidth = max(1, size.width * 0.78)
            let fitHeight = max(1, size.height * 0.90)
            let scale = min(fitWidth / imageSize.width, fitHeight / imageSize.height)
            fittedSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
            for (part, node) in cutoutNodes {
                node.size = fittedSize
                node.zRotation = 0
                node.position = cutoutRest(for: part)
            }
            return
        }
        let scale = min(size.width / 512.0, size.height / 512.0)
        fittedSize = CGSize(width: 512.0 * scale, height: 512.0 * scale)
        for node in puppetSprites() {
            node.size = fittedSize
            node.position = .zero
            node.zRotation = 0
        }
    }

    private func applyPalette() {
        guard !usesOwnerCutout else { return }
        let fill = skColor(palette.fill)
        let belly = skColor(palette.belly)
        let spot = skColor(palette.spot)
        for (part, node) in fillNodes {
            if part == .belly || part == .eye {
                node.color = part == .eye ? .white : belly
            } else {
                node.color = fill
            }
        }
        spotNode?.color = spot
        spotNode?.isHidden = !palette.hasSpots
        spotNode?.alpha = palette.hasSpots ? 0.9 : 0
    }

    private func skColor(_ color: UIColor) -> SKColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return SKColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    private func apply(_ transform: CompanionPartTransform) {
        if usesOwnerCutout {
            applyCutout(transform)
        } else {
            applyPuppet(transform)
        }
    }

    private func applyCutout(_ transform: CompanionPartTransform) {
        let torsoY = transform.bodyY
        let isWholeSprite = cutoutNodes[.head] == nil
        root.zRotation = isWholeSprite ? transform.lean * 0.45 : transform.lean

        let headRest = cutoutRest(for: .head)
        cutoutNodes[.head]?.position = CGPoint(
            x: headRest.x + transform.headX,
            y: headRest.y + transform.headY + (isWholeSprite ? 0 : torsoY)
        )
        cutoutNodes[.head]?.zRotation = transform.headRotation

        let bodyRest = cutoutRest(for: .body)
        cutoutNodes[.body]?.position = CGPoint(
            x: bodyRest.x,
            y: bodyRest.y + (isWholeSprite ? torsoY * 0.35 : torsoY)
        )
        cutoutNodes[.body]?.xScale = isWholeSprite ? 1 : transform.bodyScaleX
        cutoutNodes[.body]?.yScale = isWholeSprite ? 1 : transform.bodyScaleY

        let tailRest = cutoutRest(for: .tail)
        cutoutNodes[.tail]?.position = CGPoint(x: tailRest.x, y: tailRest.y + torsoY)
        cutoutNodes[.tail]?.zRotation = transform.tailRotation

        let frontRest = cutoutRest(for: .frontLeg)
        cutoutNodes[.frontLeg]?.position = CGPoint(
            x: frontRest.x + transform.frontLegX,
            y: frontRest.y + torsoY
        )
        let backRest = cutoutRest(for: .backLeg)
        cutoutNodes[.backLeg]?.position = CGPoint(
            x: backRest.x + transform.backLegX,
            y: backRest.y + torsoY
        )
        cutoutNodes[.frontLeg]?.zRotation = transform.frontLegRotation
        cutoutNodes[.backLeg]?.zRotation = transform.backLegRotation
        for part in [CompanionPart.head, .tail, .frontLeg, .backLeg] {
            cutoutNodes[part]?.xScale = 1
            cutoutNodes[part]?.yScale = 1
        }
    }

    private func applyPuppet(_ transform: CompanionPartTransform) {
        root.zRotation = transform.lean
        let eyeScale = CompanionRigMotion.eyeScale(time: elapsed)
        for part in PuppetPart.allCases {
            let sprites = [fillNodes[part], lineNodes[part]].compactMap { $0 }
            guard !sprites.isEmpty else { continue }
            let pose = puppetPose(for: part, transform: transform)
            for sprite in sprites {
                sprite.position = pose.position
                sprite.zRotation = pose.rotation
                if part == .body || part == .belly {
                    sprite.xScale = transform.bodyScaleX
                    sprite.yScale = transform.bodyScaleY
                } else if part == .eye {
                    sprite.xScale = 1
                    sprite.yScale = eyeScale
                } else {
                    sprite.xScale = 1
                    sprite.yScale = 1
                }
            }
        }
        if let spotNode {
            let rest = puppetRest(for: .body)
            spotNode.position = CGPoint(x: rest.x, y: rest.y + transform.bodyY)
            spotNode.xScale = transform.bodyScaleX
            spotNode.yScale = transform.bodyScaleY
        }
    }

    private func puppetPose(
        for part: PuppetPart,
        transform: CompanionPartTransform
    ) -> (position: CGPoint, rotation: CGFloat) {
        let rest = puppetRest(for: part)
        if part.followsHead {
            return (
                CGPoint(x: rest.x + transform.headX, y: rest.y + transform.headY),
                transform.headRotation
            )
        }
        switch part {
        case .tail:
            return (CGPoint(x: rest.x, y: rest.y + transform.bodyY), transform.tailRotation)
        case .frontLeg:
            return (
                CGPoint(x: rest.x + transform.frontLegX, y: rest.y + transform.bodyY),
                transform.frontLegRotation
            )
        case .backLeg:
            return (
                CGPoint(x: rest.x + transform.backLegX, y: rest.y + transform.bodyY),
                transform.backLegRotation
            )
        case .body, .belly:
            return (CGPoint(x: rest.x, y: rest.y + transform.bodyY), 0)
        default:
            return (rest, 0)
        }
    }

    private func cutoutAnchor(for part: CompanionPart) -> CGPoint {
        switch part {
        case .head:
            return CGPoint(x: 0.5, y: headAnchorY)
        case .frontLeg:
            return CGPoint(x: 0.48, y: 0.32)
        case .backLeg:
            return CGPoint(x: 0.52, y: 0.30)
        case .tail:
            return CGPoint(x: cutoutTailOnLeft ? 0.28 : 0.72, y: 0.42)
        case .body:
            return CGPoint(x: 0.5, y: 0)
        }
    }

    private func cutoutRest(for part: CompanionPart) -> CGPoint {
        let anchor = cutoutAnchor(for: part)
        return CGPoint(
            x: fittedSize.width * (anchor.x - 0.5),
            y: fittedSize.height * anchor.y
        )
    }

    private func puppetAnchor(for part: PuppetPart) -> CGPoint {
        switch part {
        case .eye:
            return CGPoint(x: 0.72, y: 0.68)
        case .head, .nearEar, .farEar:
            return CGPoint(x: 0.64, y: 0.60)
        case .frontLeg:
            return CGPoint(x: 0.58, y: 0.22)
        case .backLeg:
            return CGPoint(x: 0.42, y: 0.20)
        case .tail:
            return CGPoint(x: 0.32, y: 0.42)
        case .body, .belly:
            return CGPoint(x: 0.5, y: 0)
        }
    }

    private func puppetRest(for part: PuppetPart) -> CGPoint {
        let anchor = puppetAnchor(for: part)
        return CGPoint(
            x: fittedSize.width * (anchor.x - 0.5),
            y: fittedSize.height * anchor.y
        )
    }

    private func puppetSprites() -> [SKSpriteNode] {
        Array(fillNodes.values) + Array(lineNodes.values) + [spotNode].compactMap { $0 }
    }

    private static func isSameImage(_ lhs: PlatformImage?, _ rhs: PlatformImage?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case (let lhs?, let rhs?):
            if lhs === rhs { return true }
            return lhs.cgImage != nil && lhs.cgImage === rhs.cgImage
        default:
            return false
        }
    }
}
