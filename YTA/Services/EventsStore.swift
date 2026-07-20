import Foundation
import Observation

/// Single source of truth for the hero's "Upcoming Event" promotion.
///
/// Load order per refresh: remote feed → on failure, last good disk cache →
/// on first run, the bundled seed content. The seed ships empty by design:
/// until YTA publishes `events.json` on ytalebanon.org, there is no live
/// event to promote, so the hero button stays honestly disabled instead of
/// always advertising a generic promo.
@MainActor
@Observable
final class EventsStore {

    private(set) var events: [UpcomingEvent] = []
    private(set) var isRefreshing = false
    /// `true` when the last refresh had to fall back to cached content.
    private(set) var isShowingCachedContent = false
    /// Time of the last successful remote sync, if any.
    private(set) var lastSyncedAt: Date?

    private let api: CommunityAPI
    private var hasLoaded = false

    init(api: CommunityAPI = CommunityAPI()) {
        self.api = api
    }

    /// The event the hero button should use, if any is currently active.
    /// Past-dated entries are ignored; the first current one wins.
    var activeEvent: UpcomingEvent? {
        events.first { $0.isCurrent }
    }

    /// Whether the hero's "Upcoming Event" button should be enabled.
    var hasUpcomingEvent: Bool { activeEvent != nil }

    /// Loads content the first time a screen needs it.
    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await refresh()
    }

    /// Refreshes the event feed from remote, falling back to the disk
    /// cache and then the bundled (empty) seed content.
    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let fetched = try await api.fetchEvents()
            events = fetched
            isShowingCachedContent = false
            lastSyncedAt = .now
            DiskCache.save(fetched, as: "events-cache.json")
        } catch {
            loadFallbackContent()
        }
    }

    /// Loads the disk cache, or the bundled seed content on first run.
    private func loadFallbackContent() {
        let cached: [UpcomingEvent]? = DiskCache.load("events-cache.json")
        events = cached
            ?? SeedContent.decode("events-seed")
            ?? events
        isShowingCachedContent = true
    }
}
