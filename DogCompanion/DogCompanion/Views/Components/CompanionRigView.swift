import SwiftUI
import SpriteKit
import UIKit

struct CompanionRigView: UIViewRepresentable {
    var palette: CoatPalette
    var state: CompanionRigState
    var elapsed: TimeInterval
    var isPaused: Bool

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

        let scene = context.coordinator.scene
        scene.palette = palette
        scene.rigState = state
        scene.elapsed = elapsed
        view.presentScene(scene)
        view.isPaused = isPaused
        return view
    }

    func updateUIView(_ view: SKView, context: Context) {
        context.coordinator.scene.palette = palette
        context.coordinator.scene.rigState = state
        context.coordinator.scene.elapsed = elapsed
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
    private var fillNodes: [PuppetPart: SKSpriteNode] = [:]
    private var lineNodes: [PuppetPart: SKSpriteNode] = [:]
    private var spotNode: SKSpriteNode?
    private var fittedSize = CGSize(width: 150, height: 168)
    private var lastPalette: CoatPalette?

    var rigState: CompanionRigState = .sitting
    var elapsed: TimeInterval = 0
    var palette: CoatPalette = .brown {
        didSet {
            guard palette != lastPalette else { return }
            lastPalette = palette
            applyPalette()
        }
    }

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
        apply(CompanionRigMotion.transform(state: rigState, time: elapsed))
    }

    private func rebuild() {
        root.removeAllChildren()
        fillNodes.removeAll()
        lineNodes.removeAll()
        spotNode = nil

        for (index, part) in PuppetCatalog.drawOrder.enumerated() {
            let z = CGFloat(index)
            if let fill = makeSprite(named: part.fillName, part: part, blend: true) {
                fill.zPosition = z
                root.addChild(fill)
                fillNodes[part] = fill
            }
            if let line = makeSprite(named: part.lineName, part: part, blend: false) {
                line.zPosition = z + 0.4
                root.addChild(line)
                lineNodes[part] = line
            }
        }
        if let spots = makeSprite(named: "puppet_spots", part: .body, blend: true) {
            spots.zPosition = 2.2
            root.addChild(spots)
            spotNode = spots
        }
        applyPalette()
        layoutParts()
        applyCurrent()
    }

    private func makeSprite(named name: String, part: PuppetPart, blend: Bool) -> SKSpriteNode? {
        guard let texture = PuppetCatalog.texture(named: name) else { return nil }
        let node = SKSpriteNode(texture: texture)
        node.colorBlendFactor = blend ? 1 : 0
        node.anchorPoint = anchorPoint(for: part)
        return node
    }

    private func layoutParts() {
        guard size.width > 1, size.height > 1 else { return }
        let scale = min(size.width / 512.0, size.height / 512.0)
        fittedSize = CGSize(width: 512.0 * scale, height: 512.0 * scale)
        root.position = CGPoint(x: size.width / 2, y: 0)
        root.zRotation = 0
        for node in allSprites() {
            node.size = fittedSize
            node.position = .zero
            node.zRotation = 0
        }
    }

    private func applyPalette() {
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
        root.zRotation = transform.lean
        let eyeScale = CompanionRigMotion.eyeScale(time: elapsed)

        for part in PuppetPart.allCases {
            let sprites = sprites(for: part)
            guard !sprites.isEmpty else { continue }
            let pose = pose(for: part, transform: transform)
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
            let rest = restPosition(for: .body)
            spotNode.position = CGPoint(x: rest.x, y: rest.y + transform.bodyY)
            spotNode.xScale = transform.bodyScaleX
            spotNode.yScale = transform.bodyScaleY
            spotNode.zRotation = 0
        }
    }

    private func pose(for part: PuppetPart, transform: CompanionPartTransform) -> (position: CGPoint, rotation: CGFloat) {
        let rest = restPosition(for: part)
        if part.followsHead {
            return (
                CGPoint(x: rest.x + transform.headX, y: rest.y + transform.headY),
                transform.headRotation
            )
        }
        switch part {
        case .tail:
            return (
                CGPoint(x: rest.x, y: rest.y + transform.bodyY),
                transform.tailRotation
            )
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

    private func restPosition(for part: PuppetPart) -> CGPoint {
        let anchor = anchorPoint(for: part)
        return CGPoint(
            x: fittedSize.width * (anchor.x - 0.5),
            y: fittedSize.height * anchor.y
        )
    }

    private func anchorPoint(for part: PuppetPart) -> CGPoint {
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

    private func sprites(for part: PuppetPart) -> [SKSpriteNode] {
        [fillNodes[part], lineNodes[part]].compactMap { $0 }
    }

    private func allSprites() -> [SKSpriteNode] {
        Array(fillNodes.values) + Array(lineNodes.values) + [spotNode].compactMap { $0 }
    }
}
