import SwiftUI

/// The frontend shell: artwork backdrop, status bar, a section body, and the
/// dock with controller hints — the same structure as the Android build.
struct HomeView: View {

    enum Route: Hashable {
        case platform(PlatformSpec)
        case game(Game)
        case settings
    }

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var gamepad: GamepadManager

    @State private var path: [Route] = []
    @State private var section: DockSection = .home
    @State private var selectedIndex = 0
    @State private var showingImporter = false
    @State private var importMessage: String?

    private var platforms: [PlatformSpec] {
        settings.showEmptyPlatforms ? library.catalog.platforms : library.populatedPlatforms
    }

    private var allGames: [Game] {
        library.gamesByPlatform.values.flatMap { $0 }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    /// The platform driving the background artwork and the title pill.
    private var focusedPlatform: PlatformSpec? {
        switch section {
        case .home:
            return platforms.indices.contains(selectedIndex) ? platforms[selectedIndex] : platforms.first
        case .games:
            guard allGames.indices.contains(selectedIndex) else { return nil }
            return library.catalog.platform(id: allGames[selectedIndex].platformId)
        default:
            return nil
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                ArtworkBackground(platform: focusedPlatform)
                shell
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .platform(let platform):
                    PlatformDetailView(platform: platform)
                case .game(let game):
                    GameDetailView(game: game)
                case .settings:
                    SettingsView()
                }
            }
        }
        .sheet(isPresented: $showingImporter) {
            DocumentPicker { urls in
                showingImporter = false
                guard !urls.isEmpty else { return }
                importPicked(urls)
            }
            .ignoresSafeArea()
        }
        .alert(
            "Import",
            isPresented: Binding(
                get: { importMessage != nil },
                set: { if !$0 { importMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { importMessage = nil }
        } message: {
            Text(importMessage ?? "")
        }
        .onReceive(gamepad.events) { handle($0) }
        .onChange(of: section) { _ in selectedIndex = 0 }
    }

    // MARK: - Shell

    private var shell: some View {
        VStack(spacing: 0) {
            TopBar(
                title: titleText,
                subtitle: subtitleText,
                libraryCount: library.totalGameCount
            )
            .padding(.horizontal, 14)
            .padding(.top, 6)

            sectionBody
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomBar
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
        }
    }

    private var titleText: String {
        switch section {
        case .home:
            return focusedPlatform?.name ?? "iiSU"
        case .games:
            guard allGames.indices.contains(selectedIndex) else { return "All games" }
            return allGames[selectedIndex].title
        default:
            return section.title
        }
    }

    private var subtitleText: String? {
        switch section {
        case .home:
            guard let p = focusedPlatform else { return "No games yet" }
            return "\(library.games(for: p).count) games"
        case .games:
            return "\(allGames.count) games"
        default:
            return nil
        }
    }

    @ViewBuilder
    private var sectionBody: some View {
        switch section {
        case .home:
            homeSection
        case .games:
            gamesSection
        case .achievements:
            AchievementsPanel()
        case .community:
            CommunityPanel()
        case .settings:
            settingsSection
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var homeSection: some View {
        if library.totalGameCount == 0 && platforms.isEmpty {
            emptyLibrary
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if !library.homeShortcuts.isEmpty {
                        shortcutRow(title: "Home", games: library.homeShortcuts)
                    }
                    if !library.recentlyAdded.isEmpty {
                        shortcutRow(title: "Recently added", games: library.recentlyAdded)
                    }
                    platformGrid
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .refreshable { await library.scan() }
        }
    }

    private var platformGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Systems", subtitle: nil)
            LazyVGrid(columns: adaptiveColumns(minimum: 104), spacing: 12) {
                ForEach(Array(platforms.enumerated()), id: \.element.id) { index, platform in
                    Button {
                        path.append(.platform(platform))
                    } label: {
                        PlatformTile(
                            platform: platform,
                            gameCount: library.games(for: platform).count,
                            isSelected: index == selectedIndex,
                            accent: settings.accent.color
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var gamesSection: some View {
        ScrollView {
            LazyVGrid(columns: adaptiveColumns(minimum: 96), spacing: 12) {
                ForEach(Array(allGames.enumerated()), id: \.element.id) { index, game in
                    Button {
                        path.append(.game(game))
                    } label: {
                        GameTile(
                            game: game,
                            platform: library.catalog.platform(id: game.platformId),
                            isSelected: index == selectedIndex,
                            accent: settings.accent.color
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .refreshable { await library.scan() }
    }

    private var settingsSection: some View {
        VStack(spacing: 14) {
            Spacer()
            BrandIcon(name: "", fallbackSymbol: "gearshape.fill", size: 44)
            Text("Settings")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            Button {
                path.append(.settings)
            } label: {
                Text("Open settings")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .glass(cornerRadius: Theme.Radius.full, strong: true)
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    private func shortcutRow(title: String, games: [Game]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: title, subtitle: nil)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(games) { game in
                        Button {
                            path.append(.game(game))
                        } label: {
                            GameTile(
                                game: game,
                                platform: library.catalog.platform(id: game.platformId),
                                side: 88,
                                accent: settings.accent.color
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 3)
            }
        }
    }

    private var emptyLibrary: some View {
        VStack(spacing: 14) {
            Wordmark(height: 34)
            Text("No games yet")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            Text("""
            iOS apps cannot scan the device for ROMs the way the Android build does. \
            Put files in On My iPhone › iiSU › ROMs › <system>, or import them here.
            """)
            .font(.footnote)
            .foregroundColor(Theme.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 420)

            Button {
                showingImporter = true
            } label: {
                Label("Import ROMs", systemImage: "square.and.arrow.down")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .glass(cornerRadius: Theme.Radius.full, strong: true)
            }
            .buttonStyle(.plain)
        }
        .padding(28)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(alignment: .bottom) {
            ButtonHintBar([ButtonHint(glyph: "B", label: "Back"), ButtonHint(glyph: "⊖", label: "Details")])
            Spacer(minLength: 8)
            Dock(selection: $section)
            Spacer(minLength: 8)
            ButtonHintBar([ButtonHint(glyph: "A", label: "Select"), ButtonHint(glyph: "⊕", label: "Menu")])
        }
    }

    private func adaptiveColumns(minimum: CGFloat) -> [GridItem] {
        [GridItem(.adaptive(minimum: minimum, maximum: minimum * 1.4), spacing: 12)]
    }

    // MARK: - Actions

    private func importPicked(_ urls: [URL]) {
        do {
            let result = try library.importFiles(at: urls)
            Task { await library.scan() }
            if result.unmatched.isEmpty {
                importMessage = "Imported \(result.imported) file\(result.imported == 1 ? "" : "s")."
            } else {
                importMessage = """
                Imported \(result.imported).
                Skipped \(result.unmatched.count) with an unrecognised extension: \
                \(result.unmatched.prefix(3).joined(separator: ", "))
                """
            }
        } catch {
            importMessage = error.localizedDescription
        }
    }

    private func handle(_ event: GamepadEvent) {
        guard path.isEmpty else { return }

        let count: Int
        switch section {
        case .home: count = platforms.count
        case .games: count = allGames.count
        default: count = 0
        }

        switch event {
        case .shoulderLeft:
            section = section.previous
        case .shoulderRight:
            section = section.next
        case .menu:
            path.append(.settings)
        case .options:
            showingImporter = true
        case .left where count > 0:
            selectedIndex = max(0, selectedIndex - 1)
        case .right where count > 0:
            selectedIndex = min(count - 1, selectedIndex + 1)
        case .up where count > 0:
            selectedIndex = max(0, selectedIndex - gridStride)
        case .down where count > 0:
            selectedIndex = min(count - 1, selectedIndex + gridStride)
        case .confirm:
            openSelection()
        default:
            break
        }
    }

    /// The adaptive grid decides its own column count at layout time, so the
    /// vertical step is an approximation rather than a read of the real grid.
    private var gridStride: Int { 4 }

    private func openSelection() {
        switch section {
        case .home:
            guard platforms.indices.contains(selectedIndex) else { return }
            path.append(.platform(platforms[selectedIndex]))
        case .games:
            guard allGames.indices.contains(selectedIndex) else { return }
            path.append(.game(allGames[selectedIndex]))
        case .settings:
            path.append(.settings)
        default:
            break
        }
    }
}

private extension DockSection {
    var next: DockSection {
        let all = DockSection.allCases
        let i = all.firstIndex(of: self) ?? 0
        return all[(i + 1) % all.count]
    }

    var previous: DockSection {
        let all = DockSection.allCases
        let i = all.firstIndex(of: self) ?? 0
        return all[(i - 1 + all.count) % all.count]
    }
}
