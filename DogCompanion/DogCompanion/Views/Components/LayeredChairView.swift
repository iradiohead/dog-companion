import SwiftUI

enum ChairLayer {
    case back
    case seat
    case front
}

struct LayeredChairView: View {
    let color: Color
    let silhouette: ChairSilhouette
    let layer: ChairLayer

    var body: some View {
        ZStack(alignment: .bottom) {
            backLayer.opacity(layer == .back ? 1 : 0)
            seatLayer.opacity(layer == .seat ? 1 : 0)
            frontLayer.opacity(layer == .front ? 1 : 0)
        }
        .frame(width: width, height: 148)
        .allowsHitTesting(false)
    }

    private var width: CGFloat {
        switch silhouette {
        case .armchair: return 176
        case .roundBack: return 168
        case .sofa: return 198
        }
    }

    private var backWidth: CGFloat {
        switch silhouette {
        case .armchair: return 148
        case .roundBack: return 132
        case .sofa: return 176
        }
    }

    private var backLayer: some View {
        WobblyRoundedRectangle(cornerRadius: silhouette == .roundBack ? 54 : 26, wobble: 2.6, seed: 50)
            .fill(color.darker(by: 0.08))
            .overlay {
                WatercolorPigment(color: color.darker(by: 0.08), highlight: color.lighter(by: 0.08))
                    .clipShape(WobblyRoundedRectangle(cornerRadius: silhouette == .roundBack ? 54 : 26, wobble: 2.6, seed: 50))
            }
            .overlay {
                WobblyRoundedRectangle(cornerRadius: silhouette == .roundBack ? 52 : 24, wobble: 2.4, seed: 51)
                    .stroke(HandDrawnPalette.ink.opacity(0.38), lineWidth: 2.2)
            }
            .frame(width: backWidth, height: silhouette == .sofa ? 92 : 86)
            .padding(.bottom, 42)
    }

    private var seatLayer: some View {
        VStack(spacing: 0) {
            WobblyRoundedRectangle(cornerRadius: 22, wobble: 2.2, seed: 60)
                .fill(color)
                .overlay {
                    WatercolorPigment(color: color, highlight: color.lighter(by: 0.12))
                        .clipShape(WobblyRoundedRectangle(cornerRadius: 22, wobble: 2.2, seed: 60))
                }
                .overlay {
                    WobblyRoundedRectangle(cornerRadius: 20, wobble: 2.0, seed: 61)
                        .stroke(HandDrawnPalette.ink.opacity(0.32), lineWidth: 1.8)
                }
                .frame(width: backWidth + 8, height: 36)

            HStack(spacing: silhouette == .sofa ? 48 : 40) {
                chairLeg
                chairLeg
                if silhouette == .sofa { chairLeg }
            }
            .offset(y: -2)
        }
        .padding(.bottom, 2)
    }

    private var frontLayer: some View {
        ZStack(alignment: .bottom) {
            WobblyRoundedRectangle(cornerRadius: 16, wobble: 1.8, seed: 70)
                .fill(color.darker(by: 0.06))
                .overlay {
                    WobblyRoundedRectangle(cornerRadius: 16, wobble: 1.6, seed: 71)
                        .stroke(HandDrawnPalette.ink.opacity(0.28), lineWidth: 1.6)
                }
                .frame(width: backWidth - 10, height: 18)
                .padding(.bottom, 28)

            if silhouette != .roundBack {
                HStack {
                    arm
                    Spacer()
                    arm
                }
                .frame(width: backWidth + 18)
                .padding(.bottom, 34)
            }
        }
    }

    private var arm: some View {
        WobblyRoundedRectangle(cornerRadius: 14, wobble: 1.8, seed: 72)
            .fill(color.opacity(0.96))
            .overlay {
                WobblyRoundedRectangle(cornerRadius: 14, wobble: 1.6, seed: 73)
                    .stroke(HandDrawnPalette.ink.opacity(0.3), lineWidth: 1.5)
            }
            .frame(width: 22, height: 44)
    }

    private var chairLeg: some View {
        Capsule(style: .continuous)
            .fill(HandDrawnPalette.wood)
            .frame(width: 8, height: 26)
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(HandDrawnPalette.ink.opacity(0.25), lineWidth: 1)
            }
    }
}
