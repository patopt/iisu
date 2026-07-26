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
            BackgroundGradient()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    hero
                    playSection
                    emulatorList
                    quickSettings
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(game.title)
        .navigationBarTitleDisplayMode(.inline)
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
    }

    private var hero: some View {
        HStack(alignment: .top, spacing: 16) {
            if let platform {
                PlatformIcon(platform: platform, variant: .tile, cornerRadius: 16)
                    .frame(width: 96, height: 96)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(game.title)
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(platform?.name ?? game.platformId)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.6))
                Text("\(game.formattedSize) · \(game.fileName)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 8)
    }

    private var playSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // The share sheet is the only supported way to hand a file in our
            // container to another app's sandbox, so "Play" opens it directly.
            ShareLink(item: game.url) {
                Label("Play — send to emulator", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)

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
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Emulators", subtitle: "Detected on this device")
                ForEach(emulators) { emulator in
                    emulatorRow(emulator)
                }
            }
        }
    }

    private func emulatorRow(_ emulator: EmulatorSpec) -> some View {
        let availability = EmulatorLauncher.availability(of: emulator)
        return GlassCard(cornerRadius: 14) {
            HStack(spacing: 12) {
                Image(systemName: iconName(for: availability))
                    .font(.body.weight(.semibold))
                    .foregroundColor(tint(for: availability))
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(emulator.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                    Text(label(for: availability))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                switch availability {
                case .notInstalled:
                    Button("Get") { EmulatorLauncher.openInstallPage(emulator) }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                case .installed, .launchOnly:
                    Button("Open") { EmulatorLauncher.open(emulator) }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
            .padding(12)
        }
    }

    private var quickSettings: some View {
        VStack(alignment: .leading, spacing: 10) {
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
        GlassCard(cornerRadius: 14) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 22)
                    .foregroundColor(destructive ? .red : settings.accent.color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(destructive ? .red : .white)
                Spacer()
            }
            .padding(12)
        }
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
        case .installed: return .green
        case .launchOnly: return .yellow
        case .notInstalled: return .white.opacity(0.35)
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
