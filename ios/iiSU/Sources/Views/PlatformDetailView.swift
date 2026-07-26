import SwiftUI

@MainActor
struct PlatformDetailView: View {
    let platform: PlatformSpec

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var gamepad: GamepadManager

    @State private var selectedIndex = 0
    @State private var searchText = ""

    private let columnCount = 3

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
            BackgroundGradient()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    emulatorStatus

                    if games.isEmpty {
                        emptyState
                    } else {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columnCount),
                            spacing: 16
                        ) {
                            ForEach(Array(games.enumerated()), id: \.element.id) { index, game in
                                NavigationLink(value: HomeView.Route.game(game)) {
                                    GameTile(
                                        game: game,
                                        platform: platform,
                                        isSelected: index == selectedIndex,
                                        width: 104
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 40)
            }
        }
        .searchable(text: $searchText, prompt: "Search \(platform.shortName)")
        .navigationTitle(platform.shortName)
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(gamepad.events) { handle($0) }
    }

    private var header: some View {
        HStack(spacing: 14) {
            PlatformIcon(platform: platform, variant: .tile, cornerRadius: 14)
                .frame(width: 68, height: 68)
            VStack(alignment: .leading, spacing: 3) {
                Text(platform.name)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("\(library.games(for: platform).count) games")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.55))
            }
            Spacer()
        }
        .padding(.top, 8)
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
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(searchText.isEmpty ? "Nothing here yet" : "No matches")
                    .font(.headline)
                    .foregroundColor(.white)
                if searchText.isEmpty {
                    Text("Drop \(platform.romExtensions.prefix(4).map { "." + $0 }.joined(separator: ", ")) files into ROMs/\(platform.id)/.")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }

    private func handle(_ event: GamepadEvent) {
        guard !games.isEmpty else { return }
        switch event {
        case .left:
            selectedIndex = max(0, selectedIndex - 1)
        case .right:
            selectedIndex = min(games.count - 1, selectedIndex + 1)
        case .up:
            selectedIndex = max(0, selectedIndex - columnCount)
        case .down:
            selectedIndex = min(games.count - 1, selectedIndex + columnCount)
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
                .foregroundColor(.white.opacity(0.8))
            Text(text)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}
