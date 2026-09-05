import SwiftUI

struct ResourceDogPickerView: View {
    @Bindable var viewModel: CreationViewModel
    @State private var focusedDog: String?

    var body: some View {
        ZStack {
            PaperBackgroundView()

            if viewModel.availableDogs.isEmpty {
                ContentUnavailableView(
                    "没有可用的狗狗",
                    systemImage: "dog.fill",
                    description: Text("请在 resource/ 下添加以狗名命名的文件夹。")
                )
            } else {
                DogCoverFlowPicker(
                    dogs: viewModel.availableDogs,
                    focusedDog: $focusedDog,
                    loadPreview: viewModel.previewImage(for:),
                    onConfirm: viewModel.selectDog
                )
            }
        }
        .onAppear {
            viewModel.refreshAvailableDogs()
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
