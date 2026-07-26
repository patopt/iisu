import Foundation
import Combine

/// Owns the on-disk ROM library.
///
/// On Android iiSU scans a user-chosen folder anywhere on the device. iOS gives
/// an app no such reach, so the library lives in the app's own Documents
/// directory, which `UIFileSharingEnabled` + `LSSupportsOpeningDocumentsInPlace`
/// expose to Finder and the Files app. Users drop ROMs into `ROMs/<platform>/`
/// there, or import them through the document picker.
///
/// Not isolated at type level: it is built inside a `View`/`App` initialiser,
/// which is nonisolated. The one method that hops off the main thread carries
/// the isolation itself.
final class LibraryStore: ObservableObject {
    @Published private(set) var gamesByPlatform: [String: [Game]] = [:]
    @Published private(set) var isScanning = false
    @Published private(set) var lastScanDate: Date?
    @Published var favouriteIDs: Set<String> = [] {
        didSet { persistFavourites() }
    }
    @Published var homeShortcutIDs: [String] = [] {
        didSet { persistShortcuts() }
    }

    let catalog: EmulatorCatalog
    private let fileManager = FileManager.default
    private let defaults = UserDefaults.standard

    private enum DefaultsKey {
        static let favourites = "library.favourites"
        static let shortcuts = "library.homeShortcuts"
    }

    init(catalog: EmulatorCatalog) {
        self.catalog = catalog
        favouriteIDs = Set(defaults.stringArray(forKey: DefaultsKey.favourites) ?? [])
        homeShortcutIDs = defaults.stringArray(forKey: DefaultsKey.shortcuts) ?? []
    }

    // MARK: - Locations

    var documentsDirectory: URL {
        // Documents is guaranteed to exist for an iOS app container.
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var romsDirectory: URL {
        documentsDirectory.appendingPathComponent("ROMs", isDirectory: true)
    }

    func directory(for platform: PlatformSpec) -> URL {
        romsDirectory.appendingPathComponent(platform.id, isDirectory: true)
    }

    /// Creates `ROMs/<platform>/` for every known platform so the folder
    /// structure is discoverable in Files before any ROM exists.
    func prepareDirectories() throws {
        try fileManager.createDirectory(at: romsDirectory, withIntermediateDirectories: true)
        for platform in catalog.platforms {
            try fileManager.createDirectory(at: directory(for: platform), withIntermediateDirectories: true)
        }
    }

    // MARK: - Scanning

    @MainActor
    func scan() async {
        guard !isScanning else { return }
        isScanning = true
        defer {
            isScanning = false
            lastScanDate = Date()
        }

        try? prepareDirectories()

        let platforms = catalog.platforms
        let root = romsDirectory
        let scanned = await Task.detached(priority: .userInitiated) {
            LibraryStore.scanSync(platforms: platforms, root: root)
        }.value

        gamesByPlatform = scanned
    }

    /// Runs off the main actor — a large library is thousands of `stat` calls.
    private static func scanSync(platforms: [PlatformSpec], root: URL) -> [String: [Game]] {
        let fm = FileManager.default
        var result: [String: [Game]] = [:]
        let keys: [URLResourceKey] = [.fileSizeKey, .creationDateKey, .isDirectoryKey]

        for platform in platforms {
            let dir = root.appendingPathComponent(platform.id, isDirectory: true)
            guard let entries = try? fm.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles]
            ) else { continue }

            let allowed = platform.normalizedExtensions
            var games: [Game] = []
            for entry in entries {
                let values = try? entry.resourceValues(forKeys: Set(keys))
                if values?.isDirectory == true { continue }
                guard allowed.contains(entry.pathExtension.lowercased()) else { continue }
                games.append(
                    Game(
                        platformId: platform.id,
                        url: entry,
                        fileSize: Int64(values?.fileSize ?? 0),
                        addedAt: values?.creationDate ?? .distantPast
                    )
                )
            }
            if !games.isEmpty {
                result[platform.id] = games.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
            }
        }
        return result
    }

    // MARK: - Queries

    var populatedPlatforms: [PlatformSpec] {
        catalog.platforms.filter { !(gamesByPlatform[$0.id] ?? []).isEmpty }
    }

    var totalGameCount: Int {
        gamesByPlatform.values.reduce(0) { $0 + $1.count }
    }

    func games(for platform: PlatformSpec) -> [Game] {
        gamesByPlatform[platform.id] ?? []
    }

    func game(id: String) -> Game? {
        let platformId = String(id.split(separator: "/", maxSplits: 1).first ?? "")
        return gamesByPlatform[platformId]?.first { $0.id == id }
    }

    var favourites: [Game] {
        favouriteIDs.compactMap { game(id: $0) }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    var homeShortcuts: [Game] {
        homeShortcutIDs.compactMap { game(id: $0) }
    }

    var recentlyAdded: [Game] {
        gamesByPlatform.values.flatMap { $0 }
            .sorted { $0.addedAt > $1.addedAt }
            .prefix(12)
            .map { $0 }
    }

    // MARK: - Mutations

    func toggleFavourite(_ game: Game) {
        if favouriteIDs.contains(game.id) {
            favouriteIDs.remove(game.id)
        } else {
            favouriteIDs.insert(game.id)
        }
    }

    func toggleHomeShortcut(_ game: Game) {
        if let index = homeShortcutIDs.firstIndex(of: game.id) {
            homeShortcutIDs.remove(at: index)
        } else {
            homeShortcutIDs.append(game.id)
        }
    }

    func isOnHome(_ game: Game) -> Bool {
        homeShortcutIDs.contains(game.id)
    }

    /// Copies picked files into the platform folder implied by their extension.
    /// Returns the number of files imported and the ones we could not place.
    @discardableResult
    func importFiles(at urls: [URL]) throws -> (imported: Int, unmatched: [String]) {
        try prepareDirectories()
        var imported = 0
        var unmatched: [String] = []

        for source in urls {
            let ext = source.pathExtension.lowercased()
            guard let platform = catalog.platforms.first(where: { $0.normalizedExtensions.contains(ext) }) else {
                unmatched.append(source.lastPathComponent)
                continue
            }

            // Files handed over by the picker live outside our sandbox.
            let scoped = source.startAccessingSecurityScopedResource()
            defer { if scoped { source.stopAccessingSecurityScopedResource() } }

            let destination = uniqueDestination(
                for: source.lastPathComponent,
                in: directory(for: platform)
            )
            try fileManager.copyItem(at: source, to: destination)
            imported += 1
        }
        return (imported, unmatched)
    }

    func delete(_ game: Game) throws {
        try fileManager.removeItem(at: game.url)
        favouriteIDs.remove(game.id)
        homeShortcutIDs.removeAll { $0 == game.id }
        gamesByPlatform[game.platformId]?.removeAll { $0.id == game.id }
    }

    private func uniqueDestination(for fileName: String, in directory: URL) -> URL {
        var candidate = directory.appendingPathComponent(fileName)
        guard fileManager.fileExists(atPath: candidate.path) else { return candidate }

        let base = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        var counter = 2
        repeat {
            let name = ext.isEmpty ? "\(base) \(counter)" : "\(base) \(counter).\(ext)"
            candidate = directory.appendingPathComponent(name)
            counter += 1
        } while fileManager.fileExists(atPath: candidate.path)
        return candidate
    }

    private func persistFavourites() {
        defaults.set(Array(favouriteIDs), forKey: DefaultsKey.favourites)
    }

    private func persistShortcuts() {
        defaults.set(homeShortcutIDs, forKey: DefaultsKey.shortcuts)
    }
}
