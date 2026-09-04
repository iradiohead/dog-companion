import Foundation
import simd

/// CPU copy of the mesh-warp weights used by `CompanionBreath.metal`.
/// Keep the formulas in sync with the vertex shader.
enum CompanionMeshDeform {
    static let breathFrequency: Float = 1.55
    static let swayFrequency: Float = 1.25
    static let breathAmp: Float = 0.028
    static let swayAmp: Float = 0.016

    static func bellyWeight(u: Float, v: Float) -> Float {
        band(v, 0.42, 0.52, 0.72, 0.88) * band(u, 0.22, 0.36, 0.64, 0.80)
    }

    static func tailWeight(u: Float, v: Float) -> Float {
        let vertical = band(v, 0.48, 0.62, 0.88, 1.0)
        let left = band(u, 0.0, 0.02, 0.18, 0.32)
        let right = band(u, 0.68, 0.82, 0.98, 1.0)
        return min(1.0, vertical * (left + right))
    }

    static func displaced(
        position: SIMD2<Float>,
        uv: SIMD2<Float>,
        time: Float,
        enabled: Float
    ) -> SIMD2<Float> {
        let belly = bellyWeight(u: uv.x, v: uv.y)
        let tail = tailWeight(u: uv.x, v: uv.y)
        let breath = sin(time * breathFrequency) * breathAmp * enabled
        let sway = sin(time * swayFrequency + 0.6) * swayAmp * enabled
        var point = position
        point.y -= belly * breath
        point.x += (uv.x - 0.5) * belly * breath * 0.85
        point.x += tail * sway
        return point
    }

    static func band(_ value: Float, _ a: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
        smoothstep(a, b, value) * (1.0 - smoothstep(c, d, value))
    }

    static func smoothstep(_ edge0: Float, _ edge1: Float, _ x: Float) -> Float {
        let span = edge1 - edge0
        guard span != 0 else { return x >= edge1 ? 1 : 0 }
        let t = min(1.0, max(0.0, (x - edge0) / span))
        return t * t * (3.0 - 2.0 * t)
    }
}
