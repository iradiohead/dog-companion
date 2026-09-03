import SwiftUI
import Observation

struct StylePickerView<VM>: View where VM: ComicGenerationFlow & Observable {
    @Bindable var viewModel: VM
    var backButtonTitle: String = "重新选照片"

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("选择漫画风格")
                    .font(.title.bold())
                Text("不同风格会呈现不一样的可爱效果")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 32)

            if let preview = viewModel.sourceImage {
                Image(uiImage: preview)
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
                                Text(style.prompt.components(separatedBy: ",").prefix(2).joined(separator: ", "))
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
