import SwiftUI
import SwiftData

struct CreationFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = CreationViewModel()

    var existingCompanionName: String? = nil
    var onEnterFocusSession: () -> Void

    var body: some View {
        Group {
            switch viewModel.step {
            case .pickDog:
                pickerView
            case .generating:
                GeneratingView(
                    viewModel: viewModel,
                    title: viewModel.generatingTitle,
                    statusMessages: viewModel.generatingStatusMessages,
                    liveStatusMessage: viewModel.currentStatusMessage,
                    showsStyleBadge: viewModel.mode == .photo,
                    performGeneration: {
                        await viewModel.startGeneration(context: modelContext) {
                            onEnterFocusSession()
                        }
                    }
                )
            }
        }
        .navigationTitle("选狗狗")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var pickerView: some View {
        switch viewModel.mode {
        case .resourceCatalog:
            ResourceDogPickerView(
                viewModel: viewModel,
                existingCompanionName: existingCompanionName,
                onConfirm: confirmDog
            )
        case .photo:
            PhotoPickerView(viewModel: viewModel)
        }
    }

    private func confirmDog(_ name: String) {
        // Always reload via bundle → ResourceDogAssetCache → API; never skip using SwiftData.
        viewModel.selectDog(name)
    }
}

#Preview {
    NavigationStack {
        CreationFlowView(onEnterFocusSession: {})
    }
    .modelContainer(for: Companion.self, inMemory: true)
}
