import SwiftUI
import SwiftData

struct NamingView: View {
    @Bindable var viewModel: CreationViewModel
    @Environment(\.modelContext) private var modelContext
    @FocusState private var isNameFocused: Bool
    @State private var previewCutout: PlatformImage?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("专注时就是这只")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
                        CompanionRigView(
                            image: previewCutout,
                            palette: viewModel.selectedPalette,
                            state: .sitting,
                            elapsed: context.date.timeIntervalSinceReferenceDate,
                            isPaused: false
                        )
                        .frame(width: 230, height: 240)
                    }
                }

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
        .onChange(of: viewModel.generatedCutoutData, initial: true) { _, data in
            previewCutout = data.flatMap { PlatformImage.from(data: $0) }
        }
    }
}
