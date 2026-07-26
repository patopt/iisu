import SwiftUI
import Combine

/// User-facing preferences, mirroring the Android build's iiSU Settings.
///
/// Deliberately not `@AppStorage`: that wrapper only republishes when it lives
/// on a `View`, so inside an `ObservableObject` it would persist silently and
/// never refresh anything observing this object.
final class AppSettings: ObservableObject {

    enum BrowsingStyle: String, CaseIterable, Identifiable {
        case grid
        case carousel

        var id: String { rawValue }

        var label: String {
            switch self {
            case .grid: return "Grid"
            case .carousel: return "Carousel"
            }
        }
    }

    /// Theme accents drawn from the iiSU logo gradient.
    enum Accent: String, CaseIterable, Identifiable {
        case violet, magenta, cyan, lime, amber

        var id: String { rawValue }

        var color: Color {
            switch self {
            case .violet: return Color(hex: 0x8258FA)
            case .magenta: return Color(hex: 0xFF00BF)
            case .cyan: return Color(hex: 0x00C8FF)
            case .lime: return Color(hex: 0x7CFA58)
            case .amber: return Color(hex: 0xFFB020)
            }
        }

        var label: String { rawValue.capitalized }
    }

    @Published var accent: Accent {
        didSet { defaults.set(accent.rawValue, forKey: Key.accent) }
    }
    @Published var browsingStyle: BrowsingStyle {
        didSet { defaults.set(browsingStyle.rawValue, forKey: Key.browsingStyle) }
    }
    @Published var swapConfirmButtons: Bool {
        didSet { defaults.set(swapConfirmButtons, forKey: Key.swapConfirmButtons) }
    }
    @Published var showEmptyPlatforms: Bool {
        didSet { defaults.set(showEmptyPlatforms, forKey: Key.showEmptyPlatforms) }
    }
    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Key.hasCompletedOnboarding) }
    }
    @Published var retroAchievementsUser: String {
        didSet { defaults.set(retroAchievementsUser, forKey: Key.retroAchievementsUser) }
    }

    private let defaults: UserDefaults

    private enum Key {
        static let accent = "settings.accent"
        static let browsingStyle = "settings.browsingStyle"
        static let swapConfirmButtons = "settings.swapConfirmButtons"
        static let showEmptyPlatforms = "settings.showEmptyPlatforms"
        static let hasCompletedOnboarding = "settings.hasCompletedOnboarding"
        static let retroAchievementsUser = "settings.retroAchievementsUser"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        accent = Accent(rawValue: defaults.string(forKey: Key.accent) ?? "") ?? .violet
        browsingStyle = BrowsingStyle(rawValue: defaults.string(forKey: Key.browsingStyle) ?? "") ?? .grid
        swapConfirmButtons = defaults.bool(forKey: Key.swapConfirmButtons)
        showEmptyPlatforms = defaults.bool(forKey: Key.showEmptyPlatforms)
        hasCompletedOnboarding = defaults.bool(forKey: Key.hasCompletedOnboarding)
        retroAchievementsUser = defaults.string(forKey: Key.retroAchievementsUser) ?? ""
    }
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
