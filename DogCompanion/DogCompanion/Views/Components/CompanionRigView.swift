import SwiftUI
import SpriteKit

struct CompanionRigView: UIViewRepresentable {
    var image: PlatformImage
    var state: CompanionRigState
    var elapsed: TimeInterval
    var isPaused: Bool
    var sliceParts: Bool = true

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
        scene.sliceParts = sliceParts
        scene.image = image
        scene.rigState = state
        scene.elapsed = elapsed
        view.presentScene(scene)
        view.isPaused = isPaused
        return view
    }

    func updateUIView(_ view: SKView, context: Context) {
        context.coordinator.scene.sliceParts = sliceParts
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
    private var fittedSize = CGSize(width: 150, height: 168)
    private let headAnchorY: CGFloat = 0.52
    private var lastImage: PlatformImage?
    private var lastSliceParts = true

    var rigState: CompanionRigState = .sitting
    var elapsed: TimeInterval = 0
    var sliceParts = true {
        didSet {
            guard sliceParts != lastSliceParts else { return }
            lastSliceParts = sliceParts
            rebuild()
        }
    }

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

        let layers = sliceParts ? CompanionLayerSlicer.slice(image) : nil
        let drawOrder: [CompanionPart] = [.tail, .backLeg, .body, .frontLeg, .head]
        if let layers {
            for part in drawOrder {
                guard let partImage = layers.image(for: part) else { continue }
                let node = makeSprite(from: partImage, part: part)
                node.zPosition = CGFloat(drawOrder.firstIndex(of: part) ?? 0)
                root.addChild(node)
                nodes[part] = node
            }
        } else {
            let node = makeSprite(from: image, part: .body)
            node.zPosition = 2
            root.addChild(node)
            nodes[.body] = node
        }
        layoutParts()
        applyCurrent()
    }

    private func makeSprite(from image: UIImage, part: CompanionPart) -> SKSpriteNode {
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        let node = SKSpriteNode(texture: texture)
        if part == .head {
            node.anchorPoint = CGPoint(x: 0.5, y: headAnchorY)
        } else {
            node.anchorPoint = CGPoint(x: 0.5, y: 0)
        }
        return node
    }

    private func layoutParts() {
        guard size.width > 1, size.height > 1, let image else { return }
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return }
        let scale = min(size.width / imageSize.width, size.height / imageSize.height)
        fittedSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        root.position = CGPoint(x: size.width / 2, y: 0)
        root.zRotation = 0
        for (part, node) in nodes {
            node.size = fittedSize
            node.zRotation = 0
            node.position = restPosition(for: part)
        }
    }

    private func apply(_ transform: CompanionPartTransform) {
        let torsoY = transform.bodyY
        let isWholeSprite = nodes[.head] == nil
        root.zRotation = isWholeSprite ? transform.lean * 0.45 : transform.lean
        nodes[.head]?.position = CGPoint(
            x: transform.headX,
            y: restPosition(for: .head).y + transform.headY
        )
        nodes[.head]?.zRotation = transform.headRotation
        nodes[.head]?.xScale = 1
        nodes[.head]?.yScale = 1
        nodes[.body]?.position = CGPoint(x: 0, y: isWholeSprite ? torsoY * 0.35 : torsoY)
        nodes[.body]?.xScale = isWholeSprite ? 1 : transform.bodyScaleX
        nodes[.body]?.yScale = isWholeSprite ? 1 : transform.bodyScaleY
        nodes[.tail]?.position = CGPoint(x: 0, y: torsoY)
        nodes[.tail]?.xScale = 1
        nodes[.tail]?.yScale = 1
        nodes[.frontLeg]?.position = CGPoint(x: transform.frontLegX, y: torsoY)
        nodes[.backLeg]?.position = CGPoint(x: transform.backLegX, y: torsoY)
        nodes[.frontLeg]?.xScale = 1
        nodes[.backLeg]?.xScale = 1
        nodes[.frontLeg]?.yScale = 1
        nodes[.backLeg]?.yScale = 1
        nodes[.tail]?.zRotation = transform.tailRotation
        nodes[.frontLeg]?.zRotation = transform.frontLegRotation
        nodes[.backLeg]?.zRotation = transform.backLegRotation
    }

    private func restPosition(for part: CompanionPart) -> CGPoint {
        if part == .head {
            return CGPoint(x: 0, y: fittedSize.height * headAnchorY)
        }
        return .zero
    }
}
