import SwiftUI

@MainActor
struct PlatformDetailView: View {
    let platform: PlatformSpec

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var gamepad: GamepadManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedIndex = 0
    @State private var searchText = ""

    private var games: [Game] {
        let all = library.games(for: platform)
        guard !searchText.isEmpty else { return all }
        return all.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    private var installedEmulators: [EmulatorSpec] {
        EmulatorLauncher.installedEmulators(for: platform, in: library.catalog)
    }

    var body: some View {
        ZStack {
            ArtworkBackground(platform: platform)

            VStack(spacing: 0) {
                TopBar(
                    title: platform.name,
                    subtitle: "\(library.games(for: platform).count) games",
                    libraryCount: library.totalGameCount
                )
                .padding(.horizontal, 14)
                .padding(.top, 6)

                content

                HStack(alignment: .bottom) {
                    ButtonHintBar([ButtonHint(glyph: "B", label: "Back")])
                    Spacer()
                    ButtonHintBar([ButtonHint(glyph: "A", label: "Select")])
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onReceive(gamepad.events) { handle($0) }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero
                emulatorStatus

                if games.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 96, maximum: 134), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(Array(games.enumerated()), id: \.element.id) { index, game in
                            NavigationLink(value: HomeView.Route.game(game)) {
                                GameTile(
                                    game: game,
                                    platform: platform,
                                    isSelected: index == selectedIndex,
                                    accent: settings.accent.color
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var hero: some View {
        HStack(spacing: 14) {
            PlatformIcon(platform: platform, variant: .tile, cornerRadius: Theme.Radius.md)
                .frame(width: 72, height: 72)
            VStack(alignment: .leading, spacing: 3) {
                Text(platform.name)
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                Text(platform.romExtensions.prefix(5).map { "." + $0 }.joined(separator: " "))
                    .font(.caption2)
                    .foregroundColor(Theme.textTertiary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            searchField
        }
        .padding(12)
        .glass(cornerRadius: Theme.Radius.lg)
    }

    /// Inline rather than `.searchable`: the navigation bar is hidden so the
    /// system search field would have nowhere to appear.
    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.caption.weight(.bold))
                .foregroundColor(Theme.textTertiary)
            TextField("", text: $searchText, prompt: Text("Search").foregroundColor(Theme.textTertiary))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(Theme.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .frame(width: 130)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(Theme.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glass(cornerRadius: Theme.Radius.full)
    }

    @ViewBuilder
    private var emulatorStatus: some View {
        let all = library.catalog.emulators(for: platform)
        if all.isEmpty {
            InfoBanner(
                icon: "xmark.octagon",
                text: "No iOS emulator in the catalog covers \(platform.shortName) yet."
            )
        } else if installedEmulators.isEmpty {
            InfoBanner(
                icon: "arrow.down.app",
                text: "None of the supported emulators are installed: \(all.map(\.name).joined(separator: ", "))."
            )
        } else {
            InfoBanner(
                icon: "checkmark.seal.fill",
                text: "Ready to play with \(installedEmulators.map(\.name).joined(separator: ", "))."
            )
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(searchText.isEmpty ? "Nothing here yet" : "No matches")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            if searchText.isEmpty {
                Text("Drop \(platform.romExtensions.prefix(4).map { "." + $0 }.joined(separator: ", ")) files into ROMs/\(platform.id)/.")
                    .font(.footnote)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glass(cornerRadius: Theme.Radius.lg)
    }

    private func handle(_ event: GamepadEvent) {
        switch event {
        case .back:
            dismiss()
        case .left where !games.isEmpty:
            selectedIndex = max(0, selectedIndex - 1)
        case .right where !games.isEmpty:
            selectedIndex = min(games.count - 1, selectedIndex + 1)
        case .up where !games.isEmpty:
            selectedIndex = max(0, selectedIndex - 4)
        case .down where !games.isEmpty:
            selectedIndex = min(games.count - 1, selectedIndex + 4)
        default:
            break
        }
    }
}

struct InfoBanner: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.footnote.weight(.bold))
                .foregroundColor(Theme.textPrimary)
            Text(text)
                .font(.footnote)
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .glass(cornerRadius: Theme.Radius.sm)
    }
}
