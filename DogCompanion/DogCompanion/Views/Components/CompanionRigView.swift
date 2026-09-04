import SwiftUI
import SpriteKit

struct CompanionRigView: UIViewRepresentable {
    var image: PlatformImage
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
        scene.image = image
        scene.rigState = state
        scene.elapsed = elapsed
        view.presentScene(scene)
        view.isPaused = isPaused
        return view
    }

    func updateUIView(_ view: SKView, context: Context) {
        context.coordinator.scene.image = image
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
    private var nodes: [CompanionPart: SKSpriteNode] = [:]
    private var restY: CGFloat = 0
    private var lastImage: PlatformImage?

    var rigState: CompanionRigState = .sitting
    var elapsed: TimeInterval = 0

    var image: PlatformImage? {
        didSet {
            guard image !== lastImage else { return }
            lastImage = image
            rebuild()
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
        nodes.removeAll()
        guard let image else { return }

        let layers = CompanionLayerSlicer.slice(image)
        let drawOrder: [CompanionPart] = [.tail, .backLeg, .body, .frontLeg, .head]
        if let layers {
            for part in drawOrder {
                guard let partImage = layers.image(for: part) else { continue }
                let node = makeSprite(from: partImage)
                node.zPosition = CGFloat(drawOrder.firstIndex(of: part) ?? 0)
                root.addChild(node)
                nodes[part] = node
            }
        } else {
            let node = makeSprite(from: image)
            node.zPosition = 2
            root.addChild(node)
            nodes[.body] = node
        }
        layoutParts()
        applyCurrent()
    }

    private func makeSprite(from image: UIImage) -> SKSpriteNode {
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        let node = SKSpriteNode(texture: texture)
        node.anchorPoint = CGPoint(x: 0.5, y: 0)
        return node
    }

    private func layoutParts() {
        guard size.width > 1, size.height > 1, let image else { return }
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return }
        let scale = min(size.width / imageSize.width, size.height / imageSize.height)
        let fitted = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        restY = 0
        root.position = CGPoint(x: size.width / 2, y: 0)
        for node in nodes.values {
            node.size = fitted
            node.position = .zero
            node.zRotation = 0
        }
    }

    private func apply(_ transform: CompanionPartTransform) {
        nodes[.head]?.position = CGPoint(x: 0, y: restY + transform.headY)
        nodes[.body]?.position = CGPoint(x: 0, y: restY + transform.bodyY)
        nodes[.tail]?.position = CGPoint(x: 0, y: restY)
        nodes[.frontLeg]?.position = CGPoint(x: 0, y: restY)
        nodes[.backLeg]?.position = CGPoint(x: 0, y: restY)
        nodes[.tail]?.zRotation = transform.tailRotation
        nodes[.frontLeg]?.zRotation = transform.frontLegRotation
        nodes[.backLeg]?.zRotation = transform.backLegRotation
    }
}
