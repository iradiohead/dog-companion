import UIKit

enum PoseFrameSynthesizer {
    static func runA(from sitData: Data) -> Data? {
        render(sitData, degrees: -24, stretchX: 1.28, stretchY: 0.82, hop: -14)
    }

    static func runB(from sitData: Data) -> Data? {
        render(sitData, degrees: -10, stretchX: 0.9, stretchY: 1.12, hop: 6)
    }

    static func land(from sitData: Data) -> Data? {
        render(sitData, degrees: 8, stretchX: 1.18, stretchY: 0.72, hop: 12)
    }

    private static func render(
        _ data: Data,
        degrees: CGFloat,
        stretchX: CGFloat,
        stretchY: CGFloat,
        hop: CGFloat
    ) -> Data? {
        guard let image = UIImage(data: data), let cgImage = image.cgImage else {
            return nil
        }

        let source = CGSize(width: cgImage.width, height: cgImage.height)
        let padded = hypot(source.width * stretchX, source.height * stretchY) * 1.2
        let canvas = CGSize(width: ceil(padded), height: ceil(padded))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: canvas, format: format)
        let rendered = renderer.image { context in
            let cg = context.cgContext
            cg.translateBy(x: canvas.width / 2, y: canvas.height / 2 + hop)
            cg.rotate(by: degrees * .pi / 180)
            cg.scaleBy(x: stretchX, y: stretchY)
            let rect = CGRect(
                x: -source.width / 2,
                y: -source.height / 2,
                width: source.width,
                height: source.height
            )
            image.draw(in: rect)
        }
        return rendered.pngData()
    }
}
