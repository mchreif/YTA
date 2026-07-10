import Foundation
import Observation

/// Single source of truth for community content: broadcast alerts and
/// project polls.
///
/// Load order per refresh: remote feed → on failure, last good disk cache →
/// on first run, the bundled seed content (which doubles as format
/// documentation for the admin). Successful fetches are cached so the
/// screen works fully offline afterwards.
@MainActor
@Observable
final class CommunityStore {

    /// Segment of the Community screen, also used by deep entry points
    /// (the Home bell opens straight onto alerts).
    enum Segment: String, CaseIterable, Identifiable {
        case alerts
        case polls
        var id: String { rawValue }
    }

    // MARK: State

    private(set) var alerts: [CommunityAlert] = []
    private(set) var polls: [Poll] = []
    private(set) var isRefreshing = false
    /// `true` when the last refresh had to fall back to cached content.
    private(set) var isShowingCachedContent = false
    /// Time of the last successful remote sync, if any.
    private(set) var lastSyncedAt: Date?

    /// Segment the Community screen should open on next; consumed once.
    var requestedSegment: Segment?

    /// Alert ids the user has already seen.
    private var readAlertIDs: Set<String>
    /// pollID → optionID the user voted for on this device.
    private var votedOptions: [String: String]

    private let api: CommunityAPI
    private var hasLoaded = false

    // MARK: Persistence keys

    private enum DefaultsKey {
        static let readAlerts = "yta.read-alert-ids"
        static let knownAlerts = "yta.known-alert-ids"
        static let votes = "yta.poll-votes"
    }

    init(api: CommunityAPI = CommunityAPI()) {
        self.api = api
        let defaults = UserDefaults.standard
        readAlertIDs = Set(defaults.stringArray(forKey: DefaultsKey.readAlerts) ?? [])
        votedOptions = (defaults.dictionary(forKey: DefaultsKey.votes) as? [String: String]) ?? [:]
    }

    // MARK: Derived state

    /// Number of alerts the user hasn't opened yet — drives the tab badge
    /// and the bell on the Home screen.
    var unreadAlertCount: Int {
        alerts.filter { !readAlertIDs.contains($0.id) }.count
    }

    /// Whether an alert is still unread.
    func isUnread(_ alert: CommunityAlert) -> Bool {
        !readAlertIDs.contains(alert.id)
    }

    /// The option the user picked on this device, if they voted.
    func votedOptionID(for poll: Poll) -> String? {
        votedOptions[poll.id]
    }

    // MARK: Loading

    /// Loads content the first time a screen needs it.
    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await refresh()
    }

    /// Refreshes alerts and polls from the remote feed, falling back to
    /// the disk cache and then the bundled seed content.
    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        async let remoteAlerts = api.fetchAlerts()
        async let remotePolls = api.fetchPolls()

        do {
            let (fetchedAlerts, fetchedPolls) = try await (remoteAlerts, remotePolls)
            alerts = fetchedAlerts
            polls = fetchedPolls
            isShowingCachedContent = false
            lastSyncedAt = .now
            DiskCache.save(fetchedAlerts, as: "community-alerts.json")
            DiskCache.save(fetchedPolls, as: "community-polls.json")
            // Remember what we've seen so background refresh only
            // notifies about genuinely new alerts.
            UserDefaults.standard.set(fetchedAlerts.map(\.id), forKey: DefaultsKey.knownAlerts)
        } catch {
            loadFallbackContent()
        }
    }

    /// Loads the disk cache, or the bundled seed content on first run.
    private func loadFallbackContent() {
        let cachedAlerts: [CommunityAlert]? = DiskCache.load("community-alerts.json")
        let cachedPolls: [Poll]? = DiskCache.load("community-polls.json")

        alerts = cachedAlerts
            ?? SeedContent.decode("alerts-seed")
            ?? alerts
        polls = cachedPolls
            ?? SeedContent.decode("polls-seed")
            ?? polls
        isShowingCachedContent = true
    }

    // MARK: Actions

    /// Marks every currently visible alert as read (called when the
    /// alerts list is shown), clearing the badge.
    func markAlertsRead() {
        guard unreadAlertCount > 0 else { return }
        readAlertIDs.formUnion(alerts.map(\.id))
        UserDefaults.standard.set(Array(readAlertIDs), forKey: DefaultsKey.readAlerts)
    }

    /// Records a vote: instantly counted locally, persisted per device,
    /// then submitted to the server. If the server later returns fresher
    /// tallies, they replace the optimistic count.
    func vote(for option: Poll.Option, in poll: Poll) async {
        guard poll.isOpen, votedOptions[poll.id] == nil else { return }
        guard let pollIndex = polls.firstIndex(where: { $0.id == poll.id }),
              let optionIndex = polls[pollIndex].options.firstIndex(where: { $0.id == option.id })
        else { return }

        votedOptions[poll.id] = option.id
        UserDefaults.standard.set(votedOptions, forKey: DefaultsKey.votes)
        polls[pollIndex].options[optionIndex].votes += 1
        HapticsManager.success()

        if let updated = try? await api.submitVote(pollID: poll.id, optionID: option.id),
           let index = polls.firstIndex(where: { $0.id == updated.id }) {
            polls[index] = updated
        }
        DiskCache.save(polls, as: "community-polls.json")
    }
}

// MARK: - Disk cache

/// Tiny JSON file cache in Application Support, giving the community
/// feed full offline support after the first successful sync.
enum DiskCache {

    private static var directory: URL? {
        try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }

    static func save<T: Encodable>(_ value: T, as fileName: String) {
        guard let directory else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: directory.appending(path: fileName), options: .atomic)
    }

    static func load<T: Decodable>(_ fileName: String) -> T? {
        guard let directory,
              let data = try? Data(contentsOf: directory.appending(path: fileName))
        else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(T.self, from: data)
    }
}

// MARK: - Seed content

/// Decodes the sample content bundled with the app
/// (`Resources/Seed/*.json`). Shown only until the live feed is
/// published on ytalebanon.org.
enum SeedContent {

    static func decode<T: Decodable>(_ resourceName: String) -> T? {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(T.self, from: data)
    }
}
