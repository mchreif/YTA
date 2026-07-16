import Foundation
import Observation

/// Single source of truth for the Press tab's news articles.
///
/// Load order per refresh: remote feed → on failure, last good disk cache →
/// on first run, the bundled seed content. This mirrors `CommunityStore`'s
/// alerts/polls pattern so YTA can publish a new article the same way they
/// publish an alert: edit `news.json` on ytalebanon.org, no app update.
@MainActor
@Observable
final class NewsStore {

    private(set) var articles: [NewsArticle] = []
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

    /// Loads content the first time a screen needs it.
    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await refresh()
    }

    /// Refreshes articles from the remote feed, falling back to the disk
    /// cache and then the bundled seed content.
    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let fetched = try await api.fetchNews()
            articles = fetched
            isShowingCachedContent = false
            lastSyncedAt = .now
            DiskCache.save(fetched, as: "news-articles.json")
        } catch {
            loadFallbackContent()
        }
    }

    /// Loads the disk cache, or the bundled seed content on first run.
    private func loadFallbackContent() {
        let cached: [NewsArticle]? = DiskCache.load("news-articles.json")
        articles = cached
            ?? SeedContent.decode("news-seed")
            ?? articles
        isShowingCachedContent = true
    }
}
