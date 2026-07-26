import Foundation

/// iOS counterpart of the Android build's `emuladores.json`.
///
/// The Android frontend resolves an emulator to an explicit `Intent` plus a
/// filesystem path. iOS has no equivalent: an app cannot hand another app a
/// path into its own container. What it can do is (a) ask whether a URL scheme
/// resolves, and (b) hand the file to another app through the system document
/// handoff. The catalog is modelled around those two capabilities.
struct EmulatorCatalog: Decodable {
    let catalogVersion: Int
    let platforms: [PlatformSpec]
    let emulators: [EmulatorSpec]

    private static let resourceName = "emulators.ios"

    /// Stand-in used when the bundled catalog fails to load, so the app can
    /// still start and explain what went wrong instead of crashing at launch.
    static let empty = EmulatorCatalog(catalogVersion: 0, platforms: [], emulators: [])

    static func loadBundled() throws -> EmulatorCatalog {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            throw CatalogError.missingResource(resourceName)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(EmulatorCatalog.self, from: data)
    }

    func emulator(id: String) -> EmulatorSpec? {
        emulators.first { $0.id == id }
    }

    func platform(id: String) -> PlatformSpec? {
        platforms.first { $0.id == id }
    }

    /// Emulators declared for a platform, in catalog order (best first).
    func emulators(for platform: PlatformSpec) -> [EmulatorSpec] {
        platform.emulators.compactMap { emulator(id: $0) }
    }

    enum CatalogError: LocalizedError {
        case missingResource(String)

        var errorDescription: String? {
            switch self {
            case .missingResource(let name):
                return "\(name).json is missing from the app bundle."
            }
        }
    }
}

struct PlatformSpec: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let shortName: String
    let icon: String
    let retroAchievementsId: Int?
    let romExtensions: [String]
    let emulators: [String]

    /// Lowercased set used for extension matching during a library scan.
    var normalizedExtensions: Set<String> {
        Set(romExtensions.map { $0.lowercased() })
    }
}

struct EmulatorSpec: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let scheme: String
    let installUrl: String
    /// Whether the app registers document types and can receive a ROM through
    /// the share sheet. `false` means we can only bring the app to the front.
    let acceptsDocuments: Bool
    /// Emulators that cannot be pointed at a specific ROM at all.
    let launchOnly: Bool

    var schemeURL: URL? {
        URL(string: "\(scheme)://")
    }
}
