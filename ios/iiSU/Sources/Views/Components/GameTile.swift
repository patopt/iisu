import SwiftUI

/// Square box-art tile — the unit the whole frontend is built from.
///
/// Scraped artwork is not implemented yet, so the tile falls back to platform
/// art. It still reads visually, which is the point of the grid.
struct GameTile: View {
    let game: Game
    let platform: PlatformSpec?
    var isSelected: Bool = false
    var side: CGFloat = 96
    var accent: Color = Theme.gradient3

    var body: some View {
        ZStack(alignment: .topTrailing) {
            artwork
            if let platform {
                PlatformBadge(platform: platform)
                    .padding(5)
            }
        }
        .frame(width: side, height: side)
        .glass(cornerRadius: Theme.Radius.md, highlighted: isSelected, accent: accent)
        .scaleEffect(isSelected ? 1.06 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
    }

    private var artwork: some View {
        ZStack {
            if let platform, let image = PlatformArtwork.image(for: platform.icon, variant: .tile) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Theme.brandGradient135
            }
            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )
            VStack {
                Spacer()
                Text(game.title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 5)
                    .padding(.bottom, 6)
                    .shadow(color: .black.opacity(0.8), radius: 2)
            }
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
    }
}

/// Small system tag in the tile corner, like the USB/PSX badges in the app.
struct PlatformBadge: View {
    let platform: PlatformSpec

    var body: some View {
        Text(platform.shortName.uppercased())
            .font(.system(size: 8, weight: .heavy, design: .rounded))
            .foregroundColor(.white)
            .lineLimit(1)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(Color.black.opacity(0.55))
            )
            .overlay(
                Capsule().strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5)
            )
    }
}

/// Large platform tile used on the home grid.
struct PlatformTile: View {
    let platform: PlatformSpec
    let gameCount: Int
    var isSelected: Bool = false
    var side: CGFloat = 108
    var accent: Color = Theme.gradient3

    var body: some View {
        VStack(spacing: 0) {
            PlatformIcon(platform: platform, variant: .tile, cornerRadius: Theme.Radius.md)
                .frame(width: side, height: side)
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.7)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .frame(height: side * 0.5)
                    .clipShape(
                        RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    )
                    .allowsHitTesting(false)
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(platform.shortName)
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text("\(gameCount)")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .shadow(color: .black.opacity(0.8), radius: 2)
                    .padding(7)
                }
        }
        .glass(cornerRadius: Theme.Radius.md, highlighted: isSelected, accent: accent)
        .scaleEffect(isSelected ? 1.06 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
    }
}
