import Foundation

/// A press article about YTA and Yammouneh.
///
/// The coverage is Arabic-language regional press, so titles and summaries
/// are rendered right-to-left by the press screen. Articles are fed from
/// `https://ytalebanon.org/app/news.json` (see `NewsStore`), so YTA can
/// publish a new article without an app update. `imageName` is used for
/// the six articles bundled with the app at launch; a new article added
/// later supplies `imageURL` instead (any image already hosted on
/// ytalebanon.org works) — the card falls back to a text-only treatment
/// if neither is present.
struct NewsArticle: Identifiable, Hashable, Codable, Sendable {
    let id: String
    /// Arabic headline.
    let title: String
    /// Arabic summary.
    let summary: String
    /// Asset-catalog image name, for the articles bundled with the app.
    let imageName: String?
    /// Remote thumbnail URL, for articles published after launch.
    let imageURL: URL?
    /// External link to the full article.
    let url: URL

    /// Publication name derived from the article host,
    /// e.g. "annahar.com" → "Annahar".
    var sourceName: String {
        guard let host = url.host() else { return "" }
        let cleaned = host
            .replacingOccurrences(of: "www.", with: "")
            .split(separator: ".")
            .first
            .map(String.init) ?? host
        return cleaned.prefix(1).uppercased() + cleaned.dropFirst()
    }
}
