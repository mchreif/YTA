import Foundation

/// Networking client for the association's live content feed: alerts,
/// polls, and press articles.
///
/// The feed is a set of static JSON files plus one small PHP endpoint,
/// designed so it can live on the association's existing web hosting —
/// everything needed is in the `Server/` folder of this repository:
///
/// - `GET  /app/alerts.json` → `[CommunityAlert]`
/// - `GET  /app/polls.php`   → `[Poll]` with live tallies (falls back to
///   `polls.json` while the PHP endpoint isn't uploaded yet)
/// - `POST /app/vote.php`    → records a vote, returns the updated `Poll`
/// - `GET  /app/news.json`   → `[NewsArticle]`
struct CommunityAPI: Sendable {

    /// Errors surfaced to the store.
    enum APIError: Error {
        /// The server answered with a non-success HTTP status.
        case badStatus(Int)
    }

    /// Root of the feed on the association's website.
    let baseURL: URL

    private let session: URLSession
    private let decoder: JSONDecoder

    init(baseURL: URL = URL(string: "https://ytalebanon.org/app")!) {
        self.baseURL = baseURL

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.requestCachePolicy = .reloadRevalidatingCacheData
        session = URLSession(configuration: configuration)

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    /// Fetches all published alerts, newest first.
    func fetchAlerts() async throws -> [CommunityAlert] {
        let alerts: [CommunityAlert] = try await get("alerts.json")
        return alerts.sorted { $0.date > $1.date }
    }

    /// Fetches all polls with live tallies.
    ///
    /// Prefers the PHP endpoint (which merges recorded votes); while only
    /// the static `polls.json` exists, that file is used as-is.
    func fetchPolls() async throws -> [Poll] {
        do {
            return try await get("polls.php")
        } catch {
            return try await get("polls.json")
        }
    }

    /// Fetches all published press articles, newest first (the order
    /// YTA lists them in `news.json`).
    func fetchNews() async throws -> [NewsArticle] {
        try await get("news.json")
    }

    /// Submits one vote and returns the poll with updated tallies when the
    /// endpoint provides it. Throws when the server is unreachable — the
    /// caller keeps the optimistic local count in that case.
    func submitVote(pollID: String, optionID: String) async throws -> Poll? {
        var request = URLRequest(url: baseURL.appending(path: "vote.php"))
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var body = URLComponents()
        body.queryItems = [
            URLQueryItem(name: "poll", value: pollID),
            URLQueryItem(name: "option", value: optionID)
        ]
        request.httpBody = body.percentEncodedQuery?.data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        try Self.validate(response)
        return try? decoder.decode(Poll.self, from: data)
    }

    /// Performs a GET for a JSON resource under `baseURL`.
    private func get<T: Decodable>(_ path: String) async throws -> T {
        let (data, response) = try await session.data(from: baseURL.appending(path: path))
        try Self.validate(response)
        return try decoder.decode(T.self, from: data)
    }

    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.badStatus(http.statusCode)
        }
    }
}
