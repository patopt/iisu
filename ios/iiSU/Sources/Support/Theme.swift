import SwiftUI

/// iiSU's design tokens, taken from the "mizu" system used on iisu.network.
///
/// The site declares them in oklch; they are converted to sRGB here because
/// SwiftUI has no oklch colour space. The brand gradient is
/// `oklch(54.823% .25678 299.156) → oklch(55.472% .2377 273.219) →
/// oklch(75.752% .1364 235.14)` at 45°.
enum Theme {

    // MARK: - Brand

    static let gradient1 = Color(hex: 0x8B30ED)   // purple
    static let gradient2 = Color(hex: 0x4E57FA)   // blue-violet
    static let gradient3 = Color(hex: 0x45BDFA)   // cyan

    static let brandGradient = LinearGradient(
        colors: [gradient1, gradient2, gradient3],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )

    static let brandGradient135 = LinearGradient(
        colors: [gradient1, gradient2, gradient3],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Radii and blur (mizu scale)

    enum Radius {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let base: CGFloat = 14
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let full: CGFloat = 999
    }

    enum Blur {
        static let sm: CGFloat = 4
        static let base: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    // MARK: - Glass

    /// mizu's glass is a translucent white wash with a bright inner rim. The
    /// app renders it over dark artwork rather than the site's light page, so
    /// the fill is kept low and the rim does the work.
    static let glassFill = Color.white.opacity(0.14)
    static let glassFillStrong = Color.white.opacity(0.22)
    static let glassStroke = Color.white.opacity(0.28)
    static let glassStrokeSoft = Color.white.opacity(0.16)

    /// Scrim laid over background artwork so glass and text stay legible.
    static let artworkScrim = Color(hex: 0x0B0E14)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.72)
    static let textTertiary = Color.white.opacity(0.5)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
