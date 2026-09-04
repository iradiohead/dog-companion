import SwiftUI
import PhotosUI
import Observation
#if canImport(UIKit)
import UIKit
#endif

struct PhotoPickerView<VM>: View where VM: ComicGenerationFlow & Observable {
    @Bindable var viewModel: VM
    var title: String = PlatformCapabilities.isMac ? "选择你的狗狗" : "拍下你的狗狗"
    var subtitle: String = "我们会根据照片生成你的专属专注伙伴"

    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: PlatformCapabilities.isMac ? "photo.on.rectangle.angled" : "camera.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(.orange.gradient)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title.bold())
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let preview = viewModel.sourceImage {
                Image(platformImage: preview)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            VStack(spacing: 12) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label(
                        PlatformCapabilities.isMac ? "从文件或相册选择" : "从相册选择",
                        systemImage: "photo.on.rectangle"
                    )
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
                }

                #if !targetEnvironment(macCatalyst)
                if PlatformCapabilities.isCameraAvailable {
                    Button {
                        showCamera = true
                    } label: {
                        Label("拍照", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.orange)
                    }
                }
                #endif
            }
            .padding(.horizontal)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = PlatformImage.from(data: data) {
                    viewModel.selectPhoto(image)
                }
            }
        }
        #if !targetEnvironment(macCatalyst)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                viewModel.selectPhoto(image)
            }
            .ignoresSafeArea()
        }
        #endif
    }
}
