import SwiftUI

struct RegenerationFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: RegenerationViewModel

    init(companion: Companion) {
        _viewModel = State(initialValue: RegenerationViewModel(companion: companion))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.step {
                case .photo:
                    PhotoPickerView(
                        viewModel: viewModel,
                        title: "拍一张新照片",
                        subtitle: "用新照片重新生成漫画形象（剩余 \(viewModel.remainingRegenerations) 次）"
                    )
                case .style:
                    StylePickerView(
                        viewModel: viewModel,
                        backButtonTitle: "重新选照片"
                    )
                case .generating:
                    GeneratingView(
                        viewModel: viewModel,
                        title: "正在重新生成漫画形象"
                    )
                }
            }
            .navigationTitle("换造型")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onChange(of: viewModel.isComplete) { _, complete in
                if complete {
                    dismiss()
                }
            }
        }
    }
}
