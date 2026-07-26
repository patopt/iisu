import SwiftUI

@MainActor
struct SettingsView: View {

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var gamepad: GamepadManager
    @EnvironmentObject private var updates: UpdateChecker
    @EnvironmentObject private var achievements: RetroAchievementsClient

    @State private var apiKeyDraft: String = ""

    var body: some View {
        Form {
            appearanceSection
            inputSection
            librarySection
            retroAchievementsSection
            updatesSection
            aboutSection
        }
        .scrollContentBackground(.hidden)
        .background(BackgroundGradient())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { apiKeyDraft = achievements.apiKey }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme colour", selection: $settings.accent) {
                ForEach(AppSettings.Accent.allCases) { accent in
                    HStack {
                        Circle()
                            .fill(accent.color)
                            .frame(width: 14, height: 14)
                        Text(accent.label)
                    }
                    .tag(accent)
                }
            }

            Picker("Browsing style", selection: $settings.browsingStyle) {
                ForEach(AppSettings.BrowsingStyle.allCases) { style in
                    Text(style.label).tag(style)
                }
            }

            Toggle("Show systems with no games", isOn: $settings.showEmptyPlatforms)
        }
    }

    private var inputSection: some View {
        Section {
            Toggle("Swap A/B and X/Y buttons", isOn: $settings.swapConfirmButtons)
            LabeledContent("Controller") {
                Text(gamepad.isConnected ? (gamepad.controllerName ?? "Connected") : "None")
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("Input")
        } footer: {
            Text("Nintendo-style layout moves confirm from the bottom face button to the right one.")
        }
    }

    private var librarySection: some View {
        Section {
            LabeledContent("Games", value: "\(library.totalGameCount)")
            LabeledContent("Systems with games", value: "\(library.populatedPlatforms.count)")
            Button {
                Task { await library.scan() }
            } label: {
                if library.isScanning {
                    Label("Scanning…", systemImage: "arrow.triangle.2.circlepath")
                } else {
                    Label("Rescan library", systemImage: "arrow.clockwise")
                }
            }
            .disabled(library.isScanning)
        } header: {
            Text("Library")
        } footer: {
            Text("ROMs live in On My iPhone › iiSU › ROMs › <system>. Files added there appear after a rescan.")
        }
    }

    private var retroAchievementsSection: some View {
        Section {
            TextField("Username", text: $settings.retroAchievementsUser)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            SecureField("Web API key", text: $apiKeyDraft)
                .onSubmit { achievements.apiKey = apiKeyDraft }

            Button("Save and sync") {
                achievements.apiKey = apiKeyDraft
                Task { await achievements.loadSummary(username: settings.retroAchievementsUser) }
            }
            .disabled(settings.retroAchievementsUser.isEmpty || apiKeyDraft.isEmpty)

            achievementsStatus
        } header: {
            Text("RetroAchievements")
        } footer: {
            Text("The API key is stored in the keychain. Get yours at retroachievements.org/settings.")
        }
    }

    @ViewBuilder
    private var achievementsStatus: some View {
        switch achievements.state {
        case .signedOut:
            EmptyView()
        case .loading:
            Label("Syncing…", systemImage: "arrow.triangle.2.circlepath")
        case .loaded(let summary):
            VStack(alignment: .leading, spacing: 2) {
                Text("\(summary.username) · \(summary.points) points")
                    .font(.subheadline.weight(.semibold))
                if let rank = summary.rank {
                    Text("Rank #\(rank)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundColor(.orange)
        }
    }

    private var updatesSection: some View {
        Section("Updates") {
            LabeledContent("Version", value: "\(updates.currentVersion) (\(updates.currentBuild))")

            Button("Check for updates") {
                Task { await updates.check() }
            }

            switch updates.state {
            case .idle:
                EmptyView()
            case .checking:
                Label("Checking…", systemImage: "arrow.triangle.2.circlepath")
            case .upToDate(let current):
                Label("iiSU \(current) is the latest build", systemImage: "checkmark.circle")
                    .font(.footnote)
            case .updateAvailable(let version, let url):
                Link(destination: url) {
                    Label("iiSU \(version) is available", systemImage: "arrow.down.circle.fill")
                }
            case .failed(let message):
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }

    private var aboutSection: some View {
        Section {
            Link("Discord", destination: URL(string: "https://discord.com/invite/iisu")!)
            Link("Website", destination: URL(string: "https://iisu.network")!)
            Button("Replay onboarding") {
                settings.hasCompletedOnboarding = false
            }
        } header: {
            Text("About")
        } footer: {
            Text("iiSU for iOS is a sideload build. It cannot replace the home screen — iOS reserves that — so it runs as a standard app.")
        }
    }
}
