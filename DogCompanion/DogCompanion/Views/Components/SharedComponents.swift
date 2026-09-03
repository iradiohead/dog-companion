import SwiftUI

struct VitalStatBar: View {
    let title: String
    let value: Int
    let color: Color
    let icon: String

    private var tier: ExpressionTier {
        ExpressionTier(value: value)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(tier.emoji) \(tier.label)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.15))
                    Capsule()
                        .fill(color.gradient)
                        .frame(width: geometry.size.width * CGFloat(value) / 100)
                }
            }
            .frame(height: 10)
        }
    }
}

struct CareActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }
}

struct ComicPortraitView: View {
    let portraitData: Data?
    let hunger: Int
    let mood: Int

    private var combinedTier: ExpressionTier {
        let average = (hunger + mood) / 2
        return ExpressionTier(value: average)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let portraitData, let uiImage = UIImage(data: portraitData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "dog.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.secondary)
                        .padding(40)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 280)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 24))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .saturation(combinedTier == .critical ? 0.5 : 1.0)

            Text(combinedTier.emoji)
                .font(.largeTitle)
                .padding(10)
                .background(.ultraThinMaterial, in: Circle())
                .padding(12)
        }
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
