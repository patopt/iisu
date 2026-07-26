import SwiftUI

/// Full-bleed blurred artwork behind every screen.
///
/// iiSU's identity is that the background is the currently selected system or
/// game, blurred and dimmed, rather than a fixed colour. When nothing is
/// selected it falls back to the brand gradient.
struct ArtworkBackground: View {
    var platform: PlatformSpec? = nil

    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        ZStack {
            Theme.artworkScrim

            if let platform, let image = PlatformArtwork.image(for: platform.icon, variant: .tile) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 55, opaque: false)
                    .saturation(1.15)
                    .overlay(Theme.artworkScrim.opacity(0.55))
                    .transition(.opacity)
                    .id(platform.id)
            } else {
                Theme.brandGradient135
                    .blur(radius: 60)
                    .overlay(Theme.artworkScrim.opacity(0.45))
            }

            // Accent wash keeps the themed colour present even over artwork.
            RadialGradient(
                colors: [settings.accent.color.opacity(0.22), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 700
            )

            // The dotted texture from iisu.network, kept subtle over artwork.
            DotPattern()
                .opacity(0.10)
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.35), value: platform?.id)
    }
}

/// 24pt dot grid — the site's `radial-gradient(#cbd5e1 1.5px, transparent)`
/// background, redrawn as a Canvas so it tiles at any size.
struct DotPattern: View {
    var spacing: CGFloat = 24
    var radius: CGFloat = 1.5

    var body: some View {
        Canvas { context, size in
            let dot = Path(ellipseIn: CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2))
            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = 0
                while x < size.width {
                    context.fill(
                        dot.offsetBy(dx: x, dy: y),
                        with: .color(.white)
                    )
                    x += spacing
                }
                y += spacing
            }
        }
        .allowsHitTesting(false)
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The iiSU wordmark, shipped from the site's own asset set.
struct Wordmark: View {
    var height: CGFloat = 22

    var body: some View {
        Group {
            if let url = Bundle.main.url(forResource: "wordmark", withExtension: "png", subdirectory: "Brand"),
               let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Text("iiSU")
                    .font(.system(size: height, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.brandGradient)
            }
        }
        .frame(height: height)
    }
}

/// Dock / section icon from the iiSU icon set, with an SF Symbol fallback.
struct BrandIcon: View {
    let name: String
    let fallbackSymbol: String
    var size: CGFloat = 30

    var body: some View {
        Group {
            if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Brand"),
               let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: fallbackSymbol)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(Theme.brandGradient)
            }
        }
        .frame(width: size, height: size)
    }
}
