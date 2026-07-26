import SwiftUI
import UIKit

/// Loads the platform art recovered from the Android asset set.
///
/// The PNGs ship as a folder reference (`Platforms/` inside the bundle) rather
/// than an asset catalog, so `UIImage(named:)` will not find them — they have
/// to be resolved by URL.
enum PlatformArtwork {

    enum Variant {
        /// Square console tile.
        case tile
        /// Wide wordmark used in list rows.
        case wordmark
        case wordmarkSelected

        func fileName(for icon: String) -> String {
            switch self {
            case .tile: return icon
            case .wordmark: return "\(icon)_list"
            case .wordmarkSelected: return "\(icon)_list_selected"
            }
        }
    }

    private static let cache = NSCache<NSString, UIImage>()

    static func image(for icon: String, variant: Variant = .tile) -> UIImage? {
        let name = variant.fileName(for: icon)
        if let cached = cache.object(forKey: name as NSString) { return cached }
        guard
            let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Platforms"),
            let image = UIImage(contentsOfFile: url.path)
        else { return nil }
        cache.setObject(image, forKey: name as NSString)
        return image
    }
}

/// Platform art with a themed fallback for platforms that shipped no icon.
struct PlatformIcon: View {
    let platform: PlatformSpec
    var variant: PlatformArtwork.Variant = .tile
    var cornerRadius: CGFloat = 16

    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Group {
            if let image = PlatformArtwork.image(for: platform.icon, variant: variant) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                fallback
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var fallback: some View {
        ZStack {
            LinearGradient(
                colors: [settings.accent.color.opacity(0.65), Color(hex: 0x3700DA).opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(platform.shortName)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .padding(6)
        }
    }
}
