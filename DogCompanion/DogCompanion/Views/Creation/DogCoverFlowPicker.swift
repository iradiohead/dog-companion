import SwiftUI

struct DogCoverFlowPicker: View {
    let dogs: [String]
    @Binding var focusedDog: String?
    var loadPreview: (String) async -> PlatformImage?
    var onConfirm: (String) -> Void

    var body: some View {
        GeometryReader { geo in
            let cardSize = min(max(geo.size.width * 0.46, 168), 220)

            VStack(spacing: 24) {
                Spacer(minLength: 8)

                VStack(spacing: 8) {
                    Text("滑动选狗")
                        .font(.title.bold())
                        .foregroundStyle(HandDrawnPalette.ink)
                    Text("左右滑动挑选，停在最中间的封面")
                        .font(.subheadline)
                        .foregroundStyle(HandDrawnPalette.inkLight)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }

                coverFlow(cardSize: cardSize)
                    .frame(height: cardSize * 1.12)

                if let focusedDog {
                    Text(focusedDog)
                        .font(.title2.bold())
                        .foregroundStyle(HandDrawnPalette.ink)
                        .contentTransition(.numericText())
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

                Spacer(minLength: 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private func coverFlow(cardSize: CGFloat) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(dogs, id: \.self) { dogName in
                    DogCoverCard(
                        dogName: dogName,
                        size: cardSize,
                        isFocused: focusedDog == dogName,
                        loadPreview: loadPreview
                    )
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
        .contentMargins(.horizontal, 48, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $focusedDog, anchor: .center)
        .sensoryFeedback(.selection, trigger: focusedDog)
    }
}

private struct DogCoverCard: View {
    let dogName: String
    let size: CGFloat
    let isFocused: Bool
    let loadPreview: (String) async -> PlatformImage?

    @State private var previewImage: PlatformImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [HandDrawnPalette.cream, HandDrawnPalette.paper],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Group {
                if let previewImage {
                    Image(platformImage: previewImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    ProgressView()
                        .controlSize(.regular)
                }
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
                .strokeBorder(
                    isFocused ? HandDrawnPalette.timerGreen : HandDrawnPalette.ink.opacity(0.28),
                    lineWidth: isFocused ? 3 : 2
                )
        }
        .shadow(
            color: HandDrawnPalette.ink.opacity(isFocused ? 0.28 : 0.16),
            radius: isFocused ? 14 : 8,
            y: isFocused ? 8 : 5
        )
        .animation(.easeOut(duration: 0.2), value: isFocused)
        .task(id: dogName) {
            previewImage = await loadPreview(dogName)
        }
    }
}
