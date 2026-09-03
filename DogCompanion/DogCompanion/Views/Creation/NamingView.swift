import SwiftUI
import SwiftData

struct NamingView: View {
    @Bindable var viewModel: CreationViewModel
    @Environment(\.modelContext) private var modelContext
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            if let data = viewModel.generatedPortraitData {
                ComicPortraitView(portraitData: data, hunger: 80, mood: 80)
                    .padding(.horizontal)
            }

            VStack(spacing: 8) {
                Text("给你的狗狗起个名字")
                    .font(.title.bold())
                Text("这个名字会陪伴你们一起成长")
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
                Text("开始养狗狗")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal)
            .disabled(viewModel.companionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Spacer()
        }
        .padding()
        .onAppear {
            isNameFocused = true
        }
    }
}
