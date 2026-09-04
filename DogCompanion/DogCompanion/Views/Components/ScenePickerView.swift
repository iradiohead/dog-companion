import SwiftUI

struct GiftRevealView: View {
    let title: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gift.fill")
                .font(.system(size: 56))
                .foregroundStyle(.pink)
                .symbolEffect(.bounce, value: title)

            Text("专注完成！")
                .font(.title2.bold())

            Text(title)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("收下礼物", action: onDismiss)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(28)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

struct ScenePickerView: View {
    @Bindable var companion: Companion
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("场景") {
                    ForEach(SceneCatalog.scenes) { scene in
                        selectableRow(
                            title: scene.name,
                            subtitle: unlockLabel(for: scene.unlockAfterSessions),
                            isUnlocked: companion.isUnlocked(scene.id),
                            isSelected: companion.selectedSceneId == scene.id
                        ) {
                            companion.selectedSceneId = scene.id
                        }
                    }
                }

                Section("家具") {
                    ForEach(SceneCatalog.furniture) { item in
                        selectableRow(
                            title: item.name,
                            subtitle: unlockLabel(for: item.unlockAfterSessions),
                            isUnlocked: companion.isUnlocked(item.id),
                            isSelected: companion.selectedFurnitureId == item.id
                        ) {
                            companion.selectedFurnitureId = item.id
                        }
                    }
                }
            }
            .navigationTitle("装扮房间")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func selectableRow(
        title: String,
        subtitle: String,
        isUnlocked: Bool,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .foregroundStyle(.primary)
                    Text(isUnlocked ? subtitle : "完成 \(subtitle) 次专注解锁")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected, isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                } else if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .disabled(!isUnlocked)
    }

    private func unlockLabel(for sessions: Int) -> String {
        sessions == 0 ? "默认可用" : "第 \(sessions) 次"
    }
}
