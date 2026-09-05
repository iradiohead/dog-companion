import SwiftUI

struct ResourceDogPickerView: View {
    @Bindable var viewModel: CreationViewModel
    @State private var focusedDog: String?

    var body: some View {
        ZStack {
            PaperBackgroundView()

            Group {
                if viewModel.availableDogs.isEmpty {
                    ContentUnavailableView(
                        "没有可用的狗狗",
                        systemImage: "dog.fill",
                        description: Text("请在 App Bundle 的 resource/ 下添加以狗名命名的文件夹。")
                    )
                } else {
                    DogCoverFlowPicker(
                        dogs: viewModel.availableDogs,
                        focusedDog: $focusedDog,
                        onConfirm: { dogName in
                            viewModel.selectDog(dogName)
                        }
                    )
                }
            }
        }
        .onAppear {
            viewModel.refreshAvailableDogs()
            focusedDog = viewModel.availableDogs.first
        }
        .onChange(of: viewModel.availableDogs) { _, dogs in
            if focusedDog == nil || !(focusedDog.map { dogs.contains($0) } ?? false) {
                focusedDog = dogs.first
            }
        }
        .overlay(alignment: .bottom) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.red.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))
                    .padding()
            }
        }
    }
}
