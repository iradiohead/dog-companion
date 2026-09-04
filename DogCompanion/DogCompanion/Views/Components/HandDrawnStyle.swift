import SwiftUI

extension HandDrawnPalette {
    static let paperBase = Color(red: 0.97, green: 0.96, blue: 0.94)
    static let timerGreen = Color(red: 0.38, green: 0.72, blue: 0.48)
    static let timerGreenStroke = Color(red: 0.22, green: 0.55, blue: 0.32)
    static let startBlue = Color(red: 0.55, green: 0.78, blue: 0.95).opacity(0.45)
    static let chairGreen = Color(red: 0.52, green: 0.78, blue: 0.55)
    static let rugPurple = Color(red: 0.58, green: 0.48, blue: 0.78)
    static let wood = Color(red: 0.82, green: 0.66, blue: 0.45)
}

struct PaperBackgroundView: View {
    var body: some View {
        HandDrawnPalette.paperBase
            .overlay {
                LinearGradient(
                    colors: [
                        .white.opacity(0.35),
                        .clear,
                        HandDrawnPalette.ink.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .ignoresSafeArea()
    }
}

struct HandDrawnTextButton: View {
    let title: String
    var dotColor: Color? = nil
    var trailingIcon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let dotColor {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 8, height: 8)
                }
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(HandDrawnPalette.ink)
                if let trailingIcon {
                    Image(systemName: trailingIcon)
                        .font(.caption)
                        .foregroundStyle(Color(red: 0.95, green: 0.75, blue: 0.35))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct BottomNavBar: View {
  @Binding var selectedTab: HomeTab
  let onSelect: (HomeTab) -> Void

  var body: some View {
    HStack {
      navItem(.stats, title: "统计")
      Spacer()
      navItem(.timeline, title: "时间轴")
      Spacer()
      navItem(.decor, title: "装扮")
    }
    .padding(.horizontal, 36)
    .padding(.top, 8)
    .padding(.bottom, 12)
  }

  private func navItem(_ tab: HomeTab, title: String) -> some View {
    Button {
      selectedTab = tab
      onSelect(tab)
    } label: {
      Text(title)
        .font(.title3.weight(.semibold))
        .foregroundStyle(selectedTab == tab ? HandDrawnPalette.ink : HandDrawnPalette.inkLight)
    }
    .buttonStyle(.plain)
  }
}

enum HomeTab {
  case stats
  case timeline
  case decor
}
