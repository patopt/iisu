import SwiftUI

@MainActor
struct GameDetailView: View {
    let game: Game

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var gamepad: GamepadManager
    @Environment(\.dismiss) private var dismiss

    @State private var showingDeleteConfirmation = false
    @State private var errorMessage: String?

    private var platform: PlatformSpec? {
        library.catalog.platform(id: game.platformId)
    }

    private var emulators: [EmulatorSpec] {
        platform.map { library.catalog.emulators(for: $0) } ?? []
    }

    var body: some View {
        ZStack {
            ArtworkBackground(platform: platform)

            VStack(spacing: 0) {
                TopBar(
                    title: game.title,
                    subtitle: platform?.name,
                    libraryCount: library.totalGameCount
                )
                .padding(.horizontal, 14)
                .padding(.top, 6)

                content

                HStack(alignment: .bottom) {
                    ButtonHintBar([ButtonHint(glyph: "B", label: "Back")])
                    Spacer()
                    ButtonHintBar([ButtonHint(glyph: "A", label: "Play")])
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog(
            "Delete \(game.title)?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete from library", role: .destructive) { delete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The file is removed from the iiSU folder. This cannot be undone.")
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .onReceive(gamepad.events) { event in
            if event == .back { dismiss() }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero
                playSection
                emulatorList
                quickSettings
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var hero: some View {
        HStack(alignment: .top, spacing: 14) {
            GameTile(game: game, platform: platform, side: 104, accent: settings.accent.color)
            VStack(alignment: .leading, spacing: 4) {
                Text(game.title)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                Text(platform?.name ?? game.platformId)
                    .font(.footnote)
                    .foregroundColor(Theme.textSecondary)
                Text("\(game.formattedSize) · \(game.fileName)")
                    .font(.caption2)
                    .foregroundColor(Theme.textTertiary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
    }

    private var playSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // The share sheet is the only supported way to hand a file in our
            // container to another app's sandbox, so "Play" opens it directly.
            ShareLink(item: game.url) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text("Play — send to emulator")
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .glass(cornerRadius: Theme.Radius.full, strong: true, highlighted: true, accent: settings.accent.color)
            }

            InfoBanner(
                icon: "info.circle",
                text: """
                iOS has no equivalent of Android's intent launch, so iiSU hands the ROM to \
                the emulator through the system share sheet. Pick your emulator under \
                "Open in" — it copies the game into that app and starts it there.
                """
            )
        }
    }

    @ViewBuilder
    private var emulatorList: some View {
        if !emulators.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Emulators", subtitle: "Detected on this device")
                ForEach(emulators) { emulator in
                    emulatorRow(emulator)
                }
            }
        }
    }

    private func emulatorRow(_ emulator: EmulatorSpec) -> some View {
        let availability = EmulatorLauncher.availability(of: emulator)
        return HStack(spacing: 12) {
            Image(systemName: iconName(for: availability))
                .font(.body.weight(.semibold))
                .foregroundColor(tint(for: availability))
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(emulator.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                Text(label(for: availability))
                    .font(.caption2)
                    .foregroundColor(Theme.textTertiary)
            }

            Spacer()

            Button(availability == .notInstalled ? "Get" : "Open") {
                if availability == .notInstalled {
                    EmulatorLauncher.openInstallPage(emulator)
                } else {
                    EmulatorLauncher.open(emulator)
                }
            }
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(Theme.textPrimary)
            .padding(.horizontal, 13)
            .padding(.vertical, 6)
            .glass(cornerRadius: Theme.Radius.full)
            .buttonStyle(.plain)
        }
        .padding(12)
        .glass(cornerRadius: Theme.Radius.sm)
    }

    private var quickSettings: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Quick Settings", subtitle: nil)

            Button {
                library.toggleHomeShortcut(game)
            } label: {
                quickRow(
                    icon: library.isOnHome(game) ? "pin.slash.fill" : "pin.fill",
                    title: library.isOnHome(game) ? "Remove from home page" : "Add to home page"
                )
            }
            .buttonStyle(.plain)

            Button {
                library.toggleFavourite(game)
            } label: {
                quickRow(
                    icon: library.favouriteIDs.contains(game.id) ? "star.fill" : "star",
                    title: library.favouriteIDs.contains(game.id) ? "Remove from favourites" : "Add to favourites"
                )
            }
            .buttonStyle(.plain)

            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                quickRow(icon: "trash", title: "Delete from library", destructive: true)
            }
            .buttonStyle(.plain)
        }
    }

    private func quickRow(icon: String, title: String, destructive: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 22)
                .foregroundColor(destructive ? .red : settings.accent.color)
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(destructive ? .red : Theme.textPrimary)
            Spacer()
        }
        .padding(12)
        .glass(cornerRadius: Theme.Radius.sm)
    }

    private func delete() {
        do {
            try library.delete(game)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func iconName(for availability: EmulatorLauncher.Availability) -> String {
        switch availability {
        case .installed: return "checkmark.circle.fill"
        case .launchOnly: return "exclamationmark.circle.fill"
        case .notInstalled: return "arrow.down.circle"
        }
    }

    private func tint(for availability: EmulatorLauncher.Availability) -> Color {
        switch availability {
        case .installed: return Color(hex: 0x3FD9A0)
        case .launchOnly: return Color(hex: 0xE59E18)
        case .notInstalled: return Theme.textTertiary
        }
    }

    private func label(for availability: EmulatorLauncher.Availability) -> String {
        switch availability {
        case .installed: return "Installed · accepts ROMs from the share sheet"
        case .launchOnly: return "Installed · cannot receive a specific ROM"
        case .notInstalled: return "Not installed"
        }
    }
}
