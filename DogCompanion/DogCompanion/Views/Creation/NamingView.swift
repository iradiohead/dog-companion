import SwiftUI
import SwiftData

struct NamingView: View {
    @Bindable var viewModel: CreationViewModel
    @Environment(\.modelContext) private var modelContext
    @FocusState private var isNameFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let data = viewModel.generatedPortraitData,
                   let uiImage = PlatformImage.from(data: data) {
                    Image(platformImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal)
                }

                VStack(spacing: 6) {
                    Text("专注时它长这样")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
                    CompanionRigView(
                        palette: viewModel.selectedPalette,
                        state: .sitting,
                        elapsed: context.date.timeIntervalSinceReferenceDate,
                        isPaused: false
                    )
                    .frame(width: 180, height: 200)
                }
                }

                palettePicker

                VStack(spacing: 8) {
                    Text("给你的狗狗起个名字")
                        .font(.title.bold())
                    Text("它会陪你一起专注")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                TextField("例如：旺财、豆豆、小白", text: $viewModel.companionName)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .focused($isNameFocused)
                    .padding(.horizontal, 32)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button {
                    do {
                        try viewModel.saveCompanion(context: modelContext)
                    } catch {
                        viewModel.errorMessage = error.localizedDescription
                    }
                } label: {
                    Text("开始专注之旅")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal)
                .disabled(viewModel.companionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.vertical, 24)
        }
        .onAppear {
            isNameFocused = true
        }
    }

    private var palettePicker: some View {
        VStack(spacing: 8) {
            Text("毛色不对就点一下")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                ForEach(CoatPalette.allCases) { palette in
                    Button {
                        viewModel.selectedPalette = palette
                    } label: {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(palette.swatch)
                                .frame(width: 28, height: 28)
                                .overlay {
                                    Circle().strokeBorder(
                                        viewModel.selectedPalette == palette
                                            ? HandDrawnPalette.ink
                                            : HandDrawnPalette.ink.opacity(0.2),
                                        lineWidth: viewModel.selectedPalette == palette ? 2.5 : 1
                                    )
                                }
                            Text(palette.displayName)
                                .font(.caption2)
                                .foregroundStyle(HandDrawnPalette.ink)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
