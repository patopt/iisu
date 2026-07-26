import Foundation

/// Reads the same `updates/catalog.json` the Android build uses, and compares
/// the `ipa` artifact against the running bundle version.
///
/// iOS cannot self-install an update: sideloaded builds are refreshed through
/// AltStore/SideStore or by re-installing the IPA. So this surfaces the new
/// version and links to the release page rather than downloading anything.
final class UpdateChecker: ObservableObject {

    enum State: Equatable {
        case idle
        case checking
        case upToDate(current: String)
        case updateAvailable(version: String, releaseURL: URL)
        case failed(String)
    }

    @Published private(set) var state: State = .idle

    private let catalogURL: URL
    private let session: URLSession

    init(
        catalogURL: URL = URL(string: "https://raw.githubusercontent.com/patopt/iisu/main/updates/catalog.json")!,
        session: URLSession = .shared
    ) {
        self.catalogURL = catalogURL
        self.session = session
    }

    var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    var currentBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }

    @MainActor
    func check() async {
        state = .checking
        do {
            var request = URLRequest(url: catalogURL)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, response) = try await session.data(for: request)

            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                state = .failed("Update catalog returned HTTP \(http.statusCode).")
                return
            }

            let catalog = try JSONDecoder().decode(RemoteCatalog.self, from: data)
            guard let ipa = catalog.artifacts["ipa"] else {
                state = .failed("No iOS build is published in the update catalog yet.")
                return
            }

            if Self.isNewer(ipa.version, than: currentVersion), let url = URL(string: ipa.releasePageUrl) {
                state = .updateAvailable(version: ipa.version, releaseURL: url)
            } else {
                state = .upToDate(current: currentVersion)
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Dotted numeric comparison — the catalog uses versions like `0.0.7.3`,
    /// where a plain string compare would rank `0.0.10` below `0.0.7`.
    static func isNewer(_ candidate: String, than current: String) -> Bool {
        let lhs = candidate.split(separator: ".").map { Int($0) ?? 0 }
        let rhs = current.split(separator: ".").map { Int($0) ?? 0 }
        for index in 0..<max(lhs.count, rhs.count) {
            let l = index < lhs.count ? lhs[index] : 0
            let r = index < rhs.count ? rhs[index] : 0
            if l != r { return l > r }
        }
        return false
    }

    private struct RemoteCatalog: Decodable {
        struct Artifact: Decodable {
            let version: String
            let releasePageUrl: String
        }
        let catalogVersion: Int
        let artifacts: [String: Artifact]
    }
}
