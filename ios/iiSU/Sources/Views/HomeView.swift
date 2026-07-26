import SwiftUI

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
    @State private var selectedIndex = 0
    @State private var showingImporter = false
    @State private var importMessage: String?

    /// Platforms shown on the home screen — populated ones, or everything if
    /// the user opted to see empty systems too.
    private var platforms: [PlatformSpec] {
        settings.showEmptyPlatforms ? library.catalog.platforms : library.populatedPlatforms
    }

    private let columnCount = 3

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                BackgroundGradient()
                content
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
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
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HomeHeader(gameCount: library.totalGameCount, platformCount: library.populatedPlatforms.count)

                if library.totalGameCount == 0 {
                    EmptyLibraryCard(romsPath: library.romsDirectory.lastPathComponent) {
                        showingImporter = true
                    }
                }

                if !library.homeShortcuts.isEmpty {
                    gameRow(title: "Home", subtitle: "Pinned from Quick Settings", games: library.homeShortcuts)
                }

                if !library.recentlyAdded.isEmpty {
                    gameRow(title: "Recently added", subtitle: nil, games: library.recentlyAdded)
                }

                if !platforms.isEmpty {
                    platformSection
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 40)
        }
        .refreshable { await library.scan() }
    }

    private func gameRow(title: String, subtitle: String?, games: [Game]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: title, subtitle: subtitle)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(games) { game in
                        Button {
                            path.append(.game(game))
                        } label: {
                            GameTile(game: game, platform: library.catalog.platform(id: game.platformId))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var platformSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Systems",
                subtitle: gamepad.isConnected ? "D-pad to browse · A to open" : nil
            )

            if settings.browsingStyle == .grid {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columnCount),
                    spacing: 12
                ) {
                    ForEach(Array(platforms.enumerated()), id: \.element.id) { index, platform in
                        platformButton(platform, isSelected: index == selectedIndex)
                    }
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(platforms.enumerated()), id: \.element.id) { index, platform in
                        platformRow(platform, isSelected: index == selectedIndex)
                    }
                }
            }
        }
    }

    private func platformButton(_ platform: PlatformSpec, isSelected: Bool) -> some View {
        Button {
            path.append(.platform(platform))
        } label: {
            GlassCard(isHighlighted: isSelected) {
                VStack(spacing: 8) {
                    PlatformIcon(platform: platform, variant: .tile, cornerRadius: 12)
                        .frame(height: 84)
                        .padding(.horizontal, 10)
                        .padding(.top, 10)
                    Text(platform.shortName)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("\(library.games(for: platform).count)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                        .padding(.bottom, 10)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
    }

    private func platformRow(_ platform: PlatformSpec, isSelected: Bool) -> some View {
        Button {
            path.append(.platform(platform))
        } label: {
            GlassCard(isHighlighted: isSelected, cornerRadius: 14) {
                HStack(spacing: 14) {
                    PlatformIcon(platform: platform, variant: .tile, cornerRadius: 10)
                        .frame(width: 46, height: 46)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(platform.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text("\(library.games(for: platform).count) games")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.bold))
                        .foregroundColor(.white.opacity(0.35))
                }
                .padding(12)
            }
        }
        .buttonStyle(.plain)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            HStack(spacing: 8) {
                Text("iiSU")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: 0xC56EFF), Color(hex: 0xFF00BF)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                if gamepad.isConnected {
                    Image(systemName: "gamecontroller.fill")
                        .font(.footnote)
                        .foregroundColor(settings.accent.color)
                }
            }
        }
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button {
                showingImporter = true
            } label: {
                Image(systemName: "square.and.arrow.down")
            }
            Button {
                path.append(.settings)
            } label: {
                Image(systemName: "gearshape.fill")
            }
        }
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
        guard path.isEmpty, !platforms.isEmpty else { return }
        switch event {
        case .left:
            selectedIndex = max(0, selectedIndex - 1)
        case .right:
            selectedIndex = min(platforms.count - 1, selectedIndex + 1)
        case .up:
            let step = settings.browsingStyle == .grid ? columnCount : 1
            selectedIndex = max(0, selectedIndex - step)
        case .down:
            let step = settings.browsingStyle == .grid ? columnCount : 1
            selectedIndex = min(platforms.count - 1, selectedIndex + step)
        case .confirm:
            // A rescan can shrink the list while a selection is held.
            guard platforms.indices.contains(selectedIndex) else { return }
            path.append(.platform(platforms[selectedIndex]))
        case .menu:
            path.append(.settings)
        case .options:
            showingImporter = true
        default:
            break
        }
    }
}

private struct HomeHeader: View {
    let gameCount: Int
    let platformCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Your library")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            Text("\(gameCount) games across \(platformCount) systems")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
    }
}

private struct EmptyLibraryCard: View {
    let romsPath: String
    let onImport: () -> Void

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("No games yet", systemImage: "tray")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("""
                iOS apps cannot scan the device for ROMs the way the Android build does. \
                Put files in the app's \(romsPath)/<system>/ folder — reachable from the \
                Files app under "On My iPhone › iiSU", or over Finder file sharing — or \
                import them here.
                """)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.65))

                Button(action: onImport) {
                    Label("Import ROMs", systemImage: "square.and.arrow.down")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(16)
        }
    }
}
