import UIKit

enum CoatSampler {
    static func snap(from image: UIImage) -> CoatPalette {
        guard let sample = sampleHues(from: image) else { return .brown }
        if sample.isSpotted {
            return .spotted
        }
        if sample.value < 0.28 {
            return .black
        }
        if sample.saturation < 0.12 {
            return sample.value > 0.72 ? .white : .gray
        }
        if sample.hue < 0.14 || sample.hue > 0.92 {
            return sample.value > 0.58 ? .orange : .brown
        }
        if sample.hue < 0.20 {
            return .brown
        }
        return sample.value < 0.40 ? .black : .brown
    }

    private struct Sample {
        var hue: CGFloat
        var saturation: CGFloat
        var value: CGFloat
        var isSpotted: Bool
    }

    private static func sampleHues(from image: UIImage) -> Sample? {
        guard let cgImage = image.cgImage else { return nil }
        let width = max(1, cgImage.width / 8)
        let height = max(1, cgImage.height / 8)
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &bytes,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return nil
        }
        context.interpolationQuality = .low
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var hueSum: CGFloat = 0
        var satSum: CGFloat = 0
        var valSum: CGFloat = 0
        var count: CGFloat = 0
        var darkCount: CGFloat = 0
        var lightCount: CGFloat = 0

        var index = 0
        while index < bytes.count {
            let red = CGFloat(bytes[index]) / 255.0
            let green = CGFloat(bytes[index + 1]) / 255.0
            let blue = CGFloat(bytes[index + 2]) / 255.0
            index += 4
            let color = UIColor(red: red, green: green, blue: blue, alpha: 1)
            var hue: CGFloat = 0
            var saturation: CGFloat = 0
            var value: CGFloat = 0
            var alpha: CGFloat = 0
            color.getHue(&hue, saturation: &saturation, brightness: &value, alpha: &alpha)
            if value > 0.92 && saturation < 0.10 {
                continue
            }
            hueSum += hue
            satSum += saturation
            valSum += value
            count += 1
            if value < 0.38 {
                darkCount += 1
            } else if value > 0.72 && saturation < 0.35 {
                lightCount += 1
            }
        }

        guard count > 12 else { return nil }
        let spottedRatio = min(darkCount, lightCount) / count
        return Sample(
            hue: hueSum / count,
            saturation: satSum / count,
            value: valSum / count,
            isSpotted: spottedRatio > 0.16 && darkCount > 8 && lightCount > 8
        )
    }
}
