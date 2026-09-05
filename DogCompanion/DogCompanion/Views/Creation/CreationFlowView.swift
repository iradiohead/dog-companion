import SwiftUI
import SwiftData

struct CreationFlowView: View {
    @State private var viewModel = CreationViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.step {
                case .photo:
                    PhotoPickerView(viewModel: viewModel)
                case .generating:
                    GeneratingView(viewModel: viewModel)
                case .naming:
                    NamingView(viewModel: viewModel)
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
