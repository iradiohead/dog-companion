import SwiftUI
import Observation

struct StylePickerView<VM>: View where VM: ComicGenerationFlow & Observable {
    @Bindable var viewModel: VM
    var backButtonTitle: String = "重新选照片"

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("选择画风")
                    .font(.title.bold())
                Text("会尽量保留照片里那只狗的样子")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 32)

            if let preview = viewModel.sourceImage {
                Image(platformImage: preview)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.orange, lineWidth: 3))
            }

            VStack(spacing: 12) {
                ForEach(StyleTemplate.allCases) { style in
                    Button {
                        viewModel.selectStyle(style)
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: style.iconName)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(Color.accentColor.opacity(0.12), in: Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(style.displayName)
                                    .font(.headline)
                                Text(style.shortDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            Button(backButtonTitle) {
                viewModel.goBackToPhoto()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Spacer()
        }
    }
}
