import SwiftUI

/// Sections of the frontend, mirroring the Android build's bottom dock.
enum DockSection: String, CaseIterable, Identifiable {
    case home
    case games
    case achievements
    case community
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .games: return "Games"
        case .achievements: return "Achievements"
        case .community: return "Community"
        case .settings: return "Settings"
        }
    }

    /// Icon shipped in Resources/Brand, with an SF Symbol fallback.
    var asset: (name: String, fallback: String) {
        switch self {
        case .home: return ("icon_home", "house.fill")
        case .games: return ("icon_games", "gamecontroller.fill")
        case .achievements: return ("icon_trophy", "trophy.fill")
        case .community: return ("icon_globe", "globe")
        case .settings: return ("", "square.grid.2x2.fill")
        }
    }
}

/// The floating dock: brand icons in a glass capsule, LB/RB shoulder tags, and
/// a page indicator under the selected item.
struct Dock: View {
    @Binding var selection: DockSection

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                ShoulderTag(text: "LB")
                Spacer()
                ShoulderTag(text: "RB")
            }
            .padding(.horizontal, 6)

            HStack(spacing: 6) {
                ForEach(DockSection.allCases) { section in
                    Button {
                        selection = section
                    } label: {
                        dockItem(section)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(section.title)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .glass(cornerRadius: Theme.Radius.full, strong: true)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private func dockItem(_ section: DockSection) -> some View {
        let isSelected = section == selection
        return VStack(spacing: 4) {
            BrandIcon(name: section.asset.name, fallbackSymbol: section.asset.fallback, size: 30)
                .opacity(isSelected ? 1 : 0.55)
                .scaleEffect(isSelected ? 1.0 : 0.9)

            Capsule()
                .fill(isSelected ? Color.white : Color.clear)
                .frame(width: 22, height: 3)
        }
        .frame(width: 52)
        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: isSelected)
    }
}
