import SwiftUI
import MetalKit
import QuartzCore
import simd

struct CompanionMeshView: UIViewRepresentable {
    var image: PlatformImage
    var breathEnabled: Bool
    var isPaused: Bool

    func makeCoordinator() -> CompanionMeshRenderer {
        CompanionMeshRenderer()
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        context.coordinator.configure(view: view)
        context.coordinator.image = image
        context.coordinator.breathEnabled = breathEnabled
        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        context.coordinator.image = image
        context.coordinator.breathEnabled = breathEnabled
        view.isPaused = isPaused
        if !isPaused {
            view.preferredFramesPerSecond = 30
        }
    }
}

final class CompanionMeshRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice?
    private let commandQueue: MTLCommandQueue?
    private let pipeline: MTLRenderPipelineState?
    private let sampler: MTLSamplerState?
    private let textureLoader: MTKTextureLoader?
    private var vertexBuffer: MTLBuffer?
    private var indexBuffer: MTLBuffer?
    private var indexCount = 0
    private var texture: MTLTexture?
    private var lastImage: PlatformImage?
    private var lastDrawableSize = CGSize.zero
    private var lastTextureSize = CGSize.zero

    var breathEnabled = true
    var image: PlatformImage? {
        didSet {
            guard image !== lastImage else { return }
            lastImage = image
            reloadTexture()
        }
    }

    override init() {
        let device = MTLCreateSystemDefaultDevice()
        self.device = device
        self.commandQueue = device?.makeCommandQueue()
        self.textureLoader = device.map { MTKTextureLoader(device: $0) }

        var pipeline: MTLRenderPipelineState?
        var sampler: MTLSamplerState?
        if let device,
           let library = device.makeDefaultLibrary(),
           let vertex = library.makeFunction(name: "breath_vertex"),
           let fragment = library.makeFunction(name: "breath_fragment") {
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertex
            descriptor.fragmentFunction = fragment
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            descriptor.colorAttachments[0].isBlendingEnabled = true
            descriptor.colorAttachments[0].sourceRGBBlendFactor = .one
            descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
            descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
            descriptor.vertexDescriptor = Self.vertexDescriptor
            pipeline = try? device.makeRenderPipelineState(descriptor: descriptor)

            let samplerDescriptor = MTLSamplerDescriptor()
            samplerDescriptor.minFilter = .linear
            samplerDescriptor.magFilter = .linear
            samplerDescriptor.sAddressMode = .clampToEdge
            samplerDescriptor.tAddressMode = .clampToEdge
            sampler = device.makeSamplerState(descriptor: samplerDescriptor)
        }

        self.pipeline = pipeline
        self.sampler = sampler
        super.init()
    }

    func configure(view: MTKView) {
        view.device = device
        view.delegate = self
        view.framebufferOnly = true
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.preferredFramesPerSecond = 30
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColorMake(0, 0, 0, 0)
        view.isOpaque = false
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        view.layer.isOpaque = false
        if let metalLayer = view.layer as? CAMetalLayer {
            metalLayer.isOpaque = false
            metalLayer.pixelFormat = .bgra8Unorm
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        rebuildMeshIfNeeded(drawableSize: size)
    }

    func draw(in view: MTKView) {
        rebuildMeshIfNeeded(drawableSize: view.drawableSize)
        guard
            let commandQueue,
            let drawable = view.currentDrawable,
            let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer()
        else {
            return
        }

        guard
            let pipeline,
            let vertexBuffer,
            let indexBuffer,
            let texture,
            let sampler,
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else {
            if let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) {
                encoder.endEncoding()
            }
            commandBuffer.present(drawable)
            commandBuffer.commit()
            return
        }

        var uniforms = BreathUniforms(
            time: Float(CACurrentMediaTime()),
            breathAmp: CompanionMeshDeform.breathAmp,
            swayAmp: CompanionMeshDeform.swayAmp,
            enabled: breathEnabled ? 1 : 0,
            breathFrequency: CompanionMeshDeform.breathFrequency,
            swayFrequency: CompanionMeshDeform.swayFrequency,
            pad0: 0,
            pad1: 0
        )

        encoder.setRenderPipelineState(pipeline)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<BreathUniforms>.stride, index: 1)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.setFragmentSamplerState(sampler, index: 0)
        encoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: indexCount,
            indexType: .uint16,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0
        )
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private func reloadTexture() {
        guard let textureLoader, let image, let cgImage = Self.fixedCGImage(from: image) else {
            texture = nil
            return
        }
        let options: [MTKTextureLoader.Option: Any] = [
            .SRGB: false,
            .origin: MTKTextureLoader.Origin.topLeft
        ]
        texture = try? textureLoader.newTexture(cgImage: cgImage, options: options)
        lastTextureSize = .zero
    }

    private func rebuildMeshIfNeeded(drawableSize: CGSize) {
        guard drawableSize.width > 1, drawableSize.height > 1 else { return }
        let textureSize = CGSize(
            width: CGFloat(texture?.width ?? 0),
            height: CGFloat(texture?.height ?? 0)
        )
        guard textureSize.width > 0, textureSize.height > 0 else { return }
        if drawableSize == lastDrawableSize, textureSize == lastTextureSize, vertexBuffer != nil {
            return
        }
        lastDrawableSize = drawableSize
        lastTextureSize = textureSize
        buildGrid(drawableSize: drawableSize, textureSize: textureSize)
    }

    private func buildGrid(drawableSize: CGSize, textureSize: CGSize) {
        guard let device else { return }
        let divisions = 24
        let viewAspect = Float(drawableSize.width / drawableSize.height)
        let textureAspect = Float(textureSize.width / textureSize.height)
        var quadWidth: Float = 2
        var quadHeight: Float = 2
        if textureAspect > viewAspect {
            quadHeight = 2 * viewAspect / textureAspect
        } else {
            quadWidth = 2 * textureAspect / viewAspect
        }

        let originX = -quadWidth / 2
        let originY = Float(-1)
        let columns = divisions + 1
        var vertices: [MeshVertex] = []
        vertices.reserveCapacity(columns * columns)
        for row in 0...divisions {
            let v = Float(row) / Float(divisions)
            for column in 0...divisions {
                let u = Float(column) / Float(divisions)
                vertices.append(
                    MeshVertex(
                        position: SIMD2<Float>(originX + u * quadWidth, originY + (1 - v) * quadHeight),
                        uv: SIMD2<Float>(u, v)
                    )
                )
            }
        }

        var indices: [UInt16] = []
        indices.reserveCapacity(divisions * divisions * 6)
        for row in 0..<divisions {
            for column in 0..<divisions {
                let topLeft = UInt16(row * columns + column)
                let topRight = topLeft + 1
                let bottomLeft = topLeft + UInt16(columns)
                let bottomRight = bottomLeft + 1
                indices.append(contentsOf: [topLeft, bottomLeft, topRight, topRight, bottomLeft, bottomRight])
            }
        }

        vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: vertices.count * MemoryLayout<MeshVertex>.stride,
            options: .storageModeShared
        )
        indexBuffer = device.makeBuffer(
            bytes: indices,
            length: indices.count * MemoryLayout<UInt16>.stride,
            options: .storageModeShared
        )
        indexCount = indices.count
    }

    private static var vertexDescriptor: MTLVertexDescriptor {
        let descriptor = MTLVertexDescriptor()
        descriptor.attributes[0].format = .float2
        descriptor.attributes[0].offset = 0
        descriptor.attributes[0].bufferIndex = 0
        descriptor.attributes[1].format = .float2
        descriptor.attributes[1].offset = 8
        descriptor.attributes[1].bufferIndex = 0
        descriptor.layouts[0].stride = MemoryLayout<MeshVertex>.stride
        return descriptor
    }

    private static func fixedCGImage(from image: PlatformImage) -> CGImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }.cgImage
    }
}

private struct MeshVertex {
    var position: SIMD2<Float>
    var uv: SIMD2<Float>
}

private struct BreathUniforms {
    var time: Float
    var breathAmp: Float
    var swayAmp: Float
    var enabled: Float
    var breathFrequency: Float
    var swayFrequency: Float
    var pad0: Float
    var pad1: Float
}
