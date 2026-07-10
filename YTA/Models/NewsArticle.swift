import Foundation

/// A press article about YTA and Yammouneh.
///
/// The coverage is Arabic-language regional press, so titles and summaries
/// are rendered right-to-left by the press screen.
struct NewsArticle: Identifiable, Hashable, Sendable {
    let id: String
    /// Two-digit ordinal shown on the card ("01" … "06").
    let number: String
    /// Arabic headline.
    let title: String
    /// Arabic summary.
    let summary: String
    /// Asset-catalog image name of the article thumbnail.
    let imageName: String
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
