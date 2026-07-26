import SwiftUI

/// Box-art slot for a game.
///
/// The Android build scrapes artwork from several providers. Until that lands
/// here, the tile falls back to the platform art so the grid still reads
/// visually rather than as a list of filenames.
struct GameTile: View {
    let game: Game
    let platform: PlatformSpec?
    var isSelected: Bool = false
    var width: CGFloat = 116

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GlassCard(isHighlighted: isSelected, cornerRadius: 14) {
                ZStack {
                    if let platform {
                        PlatformIcon(platform: platform, variant: .tile, cornerRadius: 14)
                            .opacity(0.9)
                    } else {
                        Color.white.opacity(0.06)
                    }
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.55)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                }
                .frame(width: width, height: width)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Text(game.title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(width: width, alignment: .leading)
        }
    }
}
