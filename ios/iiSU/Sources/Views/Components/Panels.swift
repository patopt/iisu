import SwiftUI

/// RetroAchievements summary for the dock's trophy section.
struct AchievementsPanel: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var achievements: RetroAchievementsClient

    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            BrandIcon(name: "icon_trophy", fallbackSymbol: "trophy.fill", size: 52)

            switch achievements.state {
            case .signedOut:
                Text("RetroAchievements")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                Text("Add your username and Web API key in Settings to sync your profile.")
                    .font(.footnote)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)

            case .loading:
                Text("Syncing…")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.textSecondary)

            case .loaded(let summary):
                Text(summary.username)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                HStack(spacing: 10) {
                    statChip(value: "\(summary.points)", label: "points")
                    if let rank = summary.rank {
                        statChip(value: "#\(rank)", label: "rank")
                    }
                }
                if !summary.recentGames.isEmpty {
                    Text(summary.recentGames.prefix(3).joined(separator: " · "))
                        .font(.caption)
                        .foregroundColor(Theme.textTertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 420)
                }

            case .failed(let message):
                Text(message)
                    .font(.footnote)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
            }

            Spacer()
        }
        .padding(24)
        .task {
            guard !settings.retroAchievementsUser.isEmpty, achievements.hasCredentials else { return }
            await achievements.loadSummary(username: settings.retroAchievementsUser)
        }
    }

    private func statChip(value: String, label: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .glass(cornerRadius: Theme.Radius.sm)
    }
}

/// Community links, matching the globe icon in the dock.
struct CommunityPanel: View {
    private let links: [(title: String, subtitle: String, url: String, symbol: String)] = [
        ("Discord", "Join the community", "https://discord.com/invite/iisu", "bubble.left.and.bubble.right.fill"),
        ("Website", "iisu.network", "https://iisu.network", "globe"),
        ("Asset guide", "Make art for iiSU", "https://iisu.network/asset-guide", "paintbrush.pointed.fill"),
        ("Ko-fi", "Support the project", "https://ko-fi.com/iisunetwork", "heart.fill")
    ]

    var body: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 0)
            BrandIcon(name: "icon_globe", fallbackSymbol: "globe", size: 46)
            Text("Community")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)

            VStack(spacing: 8) {
                ForEach(links, id: \.title) { link in
                    if let url = URL(string: link.url) {
                        Link(destination: url) {
                            HStack(spacing: 12) {
                                Image(systemName: link.symbol)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Theme.brandGradient)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(link.title)
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(Theme.textPrimary)
                                    Text(link.subtitle)
                                        .font(.caption2)
                                        .foregroundColor(Theme.textTertiary)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(Theme.textTertiary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
                            .glass(cornerRadius: Theme.Radius.sm)
                        }
                    }
                }
            }
            .frame(maxWidth: 420)

            Spacer(minLength: 0)
        }
        .padding(24)
    }
}
