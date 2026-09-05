import SwiftUI

struct ResourceDogPickerView: View {
    @Bindable var viewModel: CreationViewModel

    var body: some View {
        Group {
            if viewModel.availableDogs.isEmpty {
                ContentUnavailableView(
                    "没有可用的狗狗",
                    systemImage: "dog.fill",
                    description: Text("请在 App Bundle 的 resource/ 下添加以狗名命名的文件夹。")
                )
            } else {
                List(viewModel.availableDogs, id: \.self) { dogName in
                    Button {
                        viewModel.selectDog(dogName)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "pawprint.fill")
                                .font(.title3)
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(dogName)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("从 resource/\(dogName) 加载")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.insetGrouped)
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
