import SwiftUI

struct GiftRevealView: View {
    let title: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gift.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color(red: 0.82, green: 0.55, blue: 0.38))
                .symbolEffect(.bounce, value: title)

            Text("专注完成！")
                .font(.title2.bold())
                .foregroundStyle(HandDrawnPalette.ink)

            Text(title)
                .font(.body)
                .foregroundStyle(HandDrawnPalette.inkLight)
                .multilineTextAlignment(.center)

            HandDrawnActionButton(title: "收下礼物", icon: "heart.fill", action: onDismiss)
        }
        .padding(28)
        .background(HandDrawnPalette.cream)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

struct ScenePickerView: View {
    @Bindable var companion: Companion
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    sectionHeader("墙面配色")
                    ForEach(SceneCatalog.scenes) { scene in
                        pickerCard(
                            title: scene.name,
                            subtitle: unlockLabel(for: scene.unlockAfterSessions),
                            isUnlocked: companion.isUnlocked(scene.id),
                            isSelected: companion.selectedSceneId == scene.id
                        ) {
                            companion.selectedSceneId = scene.id
                        }
                    }

                    sectionHeader("垫子 & 装饰")
                    ForEach(SceneCatalog.furniture) { item in
                        pickerCard(
                            title: item.name,
                            subtitle: unlockLabel(for: item.unlockAfterSessions),
                            isUnlocked: companion.isUnlocked(item.id),
                            isSelected: companion.selectedFurnitureId == item.id
                        ) {
                            companion.selectedFurnitureId = item.id
                        }
                    }
                }
                .padding()
            }
            .background(HandDrawnPalette.cream)
            .navigationTitle("装扮房间")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(HandDrawnPalette.ink)
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline.weight(.bold))
            .foregroundStyle(HandDrawnPalette.ink)
    }

    @ViewBuilder
    private func pickerCard(
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
                        .font(.body.weight(.semibold))
                        .foregroundStyle(HandDrawnPalette.ink)
                    Text(isUnlocked ? subtitle : "完成 \(subtitle) 次专注解锁")
                        .font(.caption)
                        .foregroundStyle(HandDrawnPalette.inkLight)
                }
                Spacer()
                if isSelected, isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(red: 0.82, green: 0.55, blue: 0.38))
                } else if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(HandDrawnPalette.inkLight)
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(HandDrawnPalette.paper)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                isSelected ? Color(red: 0.82, green: 0.55, blue: 0.38) : HandDrawnPalette.ink.opacity(0.2),
                                lineWidth: isSelected ? 2.5 : 1.5
                            )
                    }
            }
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
        .opacity(isUnlocked ? 1 : 0.55)
    }

    private func unlockLabel(for sessions: Int) -> String {
        sessions == 0 ? "默认可用" : "第 \(sessions) 次"
    }
}
