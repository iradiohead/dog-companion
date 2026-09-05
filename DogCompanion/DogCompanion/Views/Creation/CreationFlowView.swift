import SwiftUI
import SwiftData

struct CreationFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = CreationViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.step {
                case .pickDog:
                    if CompanionCreationConfig.useResourceCatalog {
                        ResourceDogPickerView(viewModel: viewModel)
                    } else {
                        PhotoPickerView(viewModel: viewModel)
                    }
                case .generating:
                    GeneratingView(
                        viewModel: viewModel,
                        title: CompanionCreationConfig.useResourceCatalog
                            ? "正在准备 \(viewModel.selectedDogName ?? "你的狗狗")"
                            : "正在生成你的专注伙伴",
                        performGeneration: {
                            await viewModel.startGeneration(context: modelContext)
                        }
                    )
                }
            }
            .navigationTitle("狗狗伙伴")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    CreationFlowView()
        .modelContainer(for: Companion.self, inMemory: true)
}
