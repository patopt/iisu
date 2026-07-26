import Foundation

/// Reads a RetroAchievements profile summary.
///
/// The Android build also hashes ROMs locally to identify games. That part is
/// unchanged conceptually but out of scope for this first iOS build: it needs
/// per-system hashing rules, and iOS gives no background window long enough to
/// hash a large library. Credentials and profile sync land first.
final class RetroAchievementsClient: ObservableObject {

    struct Summary: Equatable {
        let username: String
        let points: Int
        let rank: Int?
        let recentGames: [String]
    }

    enum State: Equatable {
        case signedOut
        case loading
        case loaded(Summary)
        case failed(String)
    }

    @Published private(set) var state: State = .signedOut

    private static let keychainAccount = "retroachievements.apiKey"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    var apiKey: String {
        get { KeychainStore.get(Self.keychainAccount) ?? "" }
        set { KeychainStore.set(newValue, for: Self.keychainAccount) }
    }

    var hasCredentials: Bool {
        !apiKey.isEmpty
    }

    @MainActor
    func loadSummary(username: String) async {
        let key = apiKey
        guard !username.isEmpty, !key.isEmpty else {
            state = .signedOut
            return
        }

        state = .loading

        var components = URLComponents(string: "https://retroachievements.org/API/API_GetUserSummary.php")
        components?.queryItems = [
            URLQueryItem(name: "z", value: username),
            URLQueryItem(name: "y", value: key),
            URLQueryItem(name: "u", value: username),
            URLQueryItem(name: "g", value: "5")
        ]
        guard let url = components?.url else {
            state = .failed("Could not build the RetroAchievements request.")
            return
        }

        do {
            let (data, response) = try await session.data(from: url)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                state = .failed("RetroAchievements returned HTTP \(http.statusCode).")
                return
            }
            let payload = try JSONDecoder().decode(UserSummary.self, from: data)
            state = .loaded(
                Summary(
                    username: payload.user ?? username,
                    points: payload.totalPoints ?? 0,
                    rank: payload.rank,
                    recentGames: (payload.recentlyPlayed ?? []).compactMap { $0.title }
                )
            )
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func signOut() {
        apiKey = ""
        state = .signedOut
    }

    /// The RA API is inconsistent about whether numbers arrive as JSON numbers
    /// or as quoted strings, and which fields appear at all depends on account
    /// state. Decode defensively rather than letting one quoted integer fail
    /// the whole response.
    private struct UserSummary: Decodable {
        let user: String?
        let totalPoints: Int?
        let rank: Int?
        let recentlyPlayed: [RecentGame]?

        enum CodingKeys: String, CodingKey {
            case user = "User"
            case totalPoints = "TotalPoints"
            case rank = "Rank"
            case recentlyPlayed = "RecentlyPlayed"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            user = try container.decodeIfPresent(String.self, forKey: .user)
            totalPoints = try container.decodeLenientInt(forKey: .totalPoints)
            rank = try container.decodeLenientInt(forKey: .rank)
            recentlyPlayed = try container.decodeIfPresent([RecentGame].self, forKey: .recentlyPlayed)
        }
    }

    private struct RecentGame: Decodable {
        let title: String?

        enum CodingKeys: String, CodingKey {
            case title = "Title"
        }
    }
}

private extension KeyedDecodingContainer {
    /// Accepts `42`, `"42"`, or a missing/null key.
    func decodeLenientInt(forKey key: Key) throws -> Int? {
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        if let string = try? decodeIfPresent(String.self, forKey: key) {
            return Int(string)
        }
        return nil
    }
}
