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
                    pickerView
                case .generating:
                    GeneratingView(
                        viewModel: viewModel,
                        title: viewModel.generatingTitle,
                        statusMessages: viewModel.generatingStatusMessages,
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

    @ViewBuilder
    private var pickerView: some View {
        switch viewModel.mode {
        case .resourceCatalog:
            ResourceDogPickerView(viewModel: viewModel)
        case .photo:
            PhotoPickerView(viewModel: viewModel)
        }
    }
}

#Preview {
    CreationFlowView()
        .modelContainer(for: Companion.self, inMemory: true)
}
