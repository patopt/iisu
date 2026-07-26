import SwiftUI

/// Condensed version of the Android onboarding flow. The steps that have no
/// iOS counterpart — replacing the home launcher, scanning arbitrary storage,
/// installing emulators for the user — are gone; the rest is kept in order.
struct OnboardingView: View {

    private enum Step: Int, CaseIterable {
        case welcome, customisation, roms, overview
    }

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var library: LibraryStore

    @State private var step: Step = .welcome
    @State private var showingImporter = false
    @State private var importedCount = 0

    var body: some View {
        ZStack {
            ArtworkBackground()
            VStack(spacing: 0) {
                progressBar
                ScrollView {
                    stepContent
                        .padding(.horizontal, 24)
                        .padding(.top, 28)
                }
                controls
            }
        }
        .sheet(isPresented: $showingImporter) {
            DocumentPicker { urls in
                showingImporter = false
                guard !urls.isEmpty else { return }
                if let result = try? library.importFiles(at: urls) {
                    importedCount += result.imported
                    Task { await library.scan() }
                }
            }
            .ignoresSafeArea()
        }
    }

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(Step.allCases, id: \.rawValue) { item in
                Capsule()
                    .fill(item.rawValue <= step.rawValue ? settings.accent.color : Color.white.opacity(0.15))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .welcome:
            VStack(alignment: .leading, spacing: 18) {
                Wordmark(height: 40)
                OnboardingPage(
                    title: "Welcome",
                    subtitle: "The visuals-first emulation frontend, now on iOS.",
                    message: """
                    iiSU organises and launches the games you already own. It is a \
                    frontend — it ships no games and no emulators.

                    One difference from the Android build: iOS does not let an app \
                    replace the home screen, so iiSU runs as a normal app here.
                    """
                )
            }
        case .customisation:
            VStack(alignment: .leading, spacing: 22) {
                OnboardingPage(
                    title: "Make it yours",
                    subtitle: "Pick a theme colour and how you want to browse.",
                    message: nil
                )
                VStack(alignment: .leading, spacing: 12) {
                    Text("Theme colour")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.textSecondary)
                    HStack(spacing: 12) {
                        ForEach(AppSettings.Accent.allCases) { accent in
                            Button {
                                settings.accent = accent
                            } label: {
                                Circle()
                                    .fill(accent.color)
                                    .frame(width: 38, height: 38)
                                    .overlay(
                                        Circle().strokeBorder(
                                            .white.opacity(settings.accent == accent ? 0.95 : 0),
                                            lineWidth: 3
                                        )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Picker("Browsing style", selection: $settings.browsingStyle) {
                        ForEach(AppSettings.BrowsingStyle.allCases) { style in
                            Text(style.label).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.top, 6)

                    Toggle("Swap A/B and X/Y buttons", isOn: $settings.swapConfirmButtons)
                        .font(.subheadline)
                        .foregroundColor(Theme.textPrimary)
                }
            }
        case .roms:
            VStack(alignment: .leading, spacing: 20) {
                OnboardingPage(
                    title: "Add your games",
                    subtitle: "iiSU reads ROMs from its own folder.",
                    message: """
                    Open the Files app, go to On My iPhone › iiSU › ROMs, and drop files into \
                    the folder for each system. You can also connect the device to a Mac or PC \
                    and use file sharing, or import straight from here.
                    """
                )
                Button {
                    showingImporter = true
                } label: {
                    Label("Import ROMs", systemImage: "square.and.arrow.down")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .glass(cornerRadius: Theme.Radius.full, strong: true)
                }
                .buttonStyle(.plain)

                if importedCount > 0 {
                    Label("\(importedCount) file\(importedCount == 1 ? "" : "s") imported", systemImage: "checkmark.circle.fill")
                        .font(.footnote)
                        .foregroundColor(.green)
                }
            }
        case .overview:
            OnboardingPage(
                title: "You're set",
                subtitle: "\(library.totalGameCount) games across \(library.populatedPlatforms.count) systems.",
                message: """
                To play a game, open it and use Play — iiSU hands the ROM to an installed \
                emulator through the iOS share sheet.

                You can rerun this walkthrough any time from Settings.
                """
            )
        }
    }

    private var controls: some View {
        HStack {
            if step != .welcome {
                Button("Back") {
                    step = Step(rawValue: step.rawValue - 1) ?? .welcome
                }
                .buttonStyle(.plain)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.textSecondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 11)
                .glass(cornerRadius: Theme.Radius.full)
            }
            Spacer()
            Button(step == .overview ? "Start" : "Next") {
                if step == .overview {
                    settings.hasCompletedOnboarding = true
                } else {
                    step = Step(rawValue: step.rawValue + 1) ?? .overview
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundColor(Theme.textPrimary)
            .padding(.horizontal, 24)
            .padding(.vertical, 11)
            .glass(cornerRadius: Theme.Radius.full, strong: true, highlighted: true, accent: settings.accent.color)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }
}

private struct OnboardingPage: View {
    let title: String
    let subtitle: String
    let message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            Text(subtitle)
                .font(.headline)
                .foregroundColor(Theme.textSecondary)
            if let message {
                Text(message)
                    .font(.callout)
                    .foregroundColor(Theme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
