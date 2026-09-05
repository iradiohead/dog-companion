import SwiftUI

struct DogCoverFlowPicker: View {
    let dogs: [String]
    @Binding var focusedDog: String?
    var onConfirm: (String) -> Void

    private let cardSize: CGFloat = 200

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Text("滑动选狗")
                .font(.title.bold())
                .foregroundStyle(HandDrawnPalette.ink)

            Text("像 iPod 选唱片一样，左右滑动挑选你的专注伙伴")
                .font(.subheadline)
                .foregroundStyle(HandDrawnPalette.inkLight)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            coverFlow
                .frame(height: cardSize * 1.15)

            if let focusedDog {
                VStack(spacing: 6) {
                    Text(focusedDog)
                        .font(.title2.bold())
                        .foregroundStyle(HandDrawnPalette.ink)
                    Text("resource/\(focusedDog)")
                        .font(.caption)
                        .foregroundStyle(HandDrawnPalette.inkLight)
                }
                .animation(.easeInOut(duration: 0.2), value: focusedDog)
            }

            Button {
                if let focusedDog {
                    onConfirm(focusedDog)
                }
            } label: {
                Text("就选它了")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 32)
            .disabled(focusedDog == nil)

            Spacer()
        }
        .onAppear {
            if focusedDog == nil {
                focusedDog = dogs.first
            }
        }
        .onChange(of: dogs) { _, newDogs in
            if focusedDog == nil || !(focusedDog.map { newDogs.contains($0) } ?? false) {
                focusedDog = newDogs.first
            }
        }
    }

    private var coverFlow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 18) {
                ForEach(dogs, id: \.self) { dogName in
                    DogCoverCard(dogName: dogName, size: cardSize)
                        .scrollTransition(axis: .horizontal) { content, phase in
                            content
                                .scaleEffect(phase.isIdentity ? 1.0 : 0.76)
                                .rotation3DEffect(
                                    .degrees(Double(phase.value) * -58),
                                    axis: (x: 0, y: 1, z: 0),
                                    perspective: 0.45
                                )
                                .opacity(phase.isIdentity ? 1.0 : max(0.4, 1.0 - abs(phase.value) * 0.55))
                                .offset(y: abs(phase.value) * 10)
                        }
                        .id(dogName)
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, 56, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $focusedDog, anchor: .center)
    }
}

private struct DogCoverCard: View {
    let dogName: String
    let size: CGFloat

    @State private var previewImage: PlatformImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            HandDrawnPalette.cream,
                            HandDrawnPalette.paper
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let previewImage {
                Image(platformImage: previewImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "dog.fill")
                    .font(.system(size: size * 0.28))
                    .foregroundStyle(.orange.opacity(0.45))
            }

            LinearGradient(
                colors: [.clear, HandDrawnPalette.ink.opacity(0.55)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack {
                Spacer()
                Text(dogName)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                    .padding(.bottom, 14)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(HandDrawnPalette.ink.opacity(0.28), lineWidth: 2)
        }
        .shadow(color: HandDrawnPalette.ink.opacity(0.22), radius: 10, y: 6)
        .task(id: dogName) {
            previewImage = loadPreview(for: dogName)
        }
    }

    private func loadPreview(for dogName: String) -> PlatformImage? {
        guard let url = ResourceDogCatalog().previewImageURL(for: dogName),
              let data = try? Data(contentsOf: url) else { return nil }
        return PlatformImage.from(data: data)
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var focused: String? = "雪纳瑞"

        var body: some View {
            ZStack {
                PaperBackgroundView()
                DogCoverFlowPicker(
                    dogs: ["雪纳瑞", "金毛"],
                    focusedDog: $focused,
                    onConfirm: { _ in }
                )
            }
        }
    }

    return PreviewHost()
}
