import Foundation
import UIKit

/// Resolves how a ROM can reach an emulator on iOS.
///
/// There is no public API that launches a third-party emulator against a file
/// in our container. Two mechanisms exist and iiSU uses both:
///
/// 1. `canOpenURL` / `open` — brings a known emulator to the front. Requires
///    the scheme to be listed in `LSApplicationQueriesSchemes`, otherwise the
///    check silently returns `false`.
/// 2. The system document handoff (share sheet) — copies the ROM into the
///    emulator's own container. This is the only route that actually transfers
///    a specific game, so it is the default action.
@MainActor
enum EmulatorLauncher {

    enum Availability {
        case installed
        case notInstalled
        /// Present, but cannot be handed a specific ROM.
        case launchOnly
    }

    static func availability(of emulator: EmulatorSpec) -> Availability {
        guard let url = emulator.schemeURL, UIApplication.shared.canOpenURL(url) else {
            return .notInstalled
        }
        return emulator.launchOnly || !emulator.acceptsDocuments ? .launchOnly : .installed
    }

    static func isInstalled(_ emulator: EmulatorSpec) -> Bool {
        availability(of: emulator) != .notInstalled
    }

    /// Emulators for this platform that are actually present on the device.
    static func installedEmulators(for platform: PlatformSpec, in catalog: EmulatorCatalog) -> [EmulatorSpec] {
        catalog.emulators(for: platform).filter { isInstalled($0) }
    }

    /// Brings the emulator to the front without a ROM.
    static func open(_ emulator: EmulatorSpec) {
        guard let url = emulator.schemeURL else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    /// Opens the emulator's install page in Safari.
    static func openInstallPage(_ emulator: EmulatorSpec) {
        guard let url = URL(string: emulator.installUrl) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
