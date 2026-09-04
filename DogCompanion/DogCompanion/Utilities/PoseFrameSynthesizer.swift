import UIKit

enum PoseFrameSynthesizer {
    static func runA(from sitData: Data) -> Data? {
        render(sitData, degrees: -9, stretchX: 1.08, stretchY: 0.96, hop: -4)
    }

    static func runB(from sitData: Data) -> Data? {
        render(sitData, degrees: -16, stretchX: 0.97, stretchY: 1.05, hop: -8)
    }

    static func land(from sitData: Data) -> Data? {
        render(sitData, degrees: 5, stretchX: 1.1, stretchY: 0.86, hop: 6)
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
        let padded = hypot(source.width * stretchX, source.height * stretchY) * 1.15
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
