import Foundation

/// A post on the association's Instagram profile (@yta_leb).
///
/// The website renders these as embedded iframes; embeds are web-only, so the
/// native app shows branded cards with the same engagement stats and links
/// out to the Instagram app / website. Post identifiers and stats mirror
/// `assets/js/yta-instagram-feed.js` on the website.
struct InstagramPost: Identifiable, Hashable, Sendable {

    /// Kind of Instagram content.
    enum Kind: String, Sendable {
        case post = "p"
        case reel
    }

    /// Instagram shortcode, e.g. "DPjpuidDMbP".
    let id: String
    let kind: Kind
    let likes: Int
    let comments: Int
    /// View count — only present for reels.
    let views: Int?

    /// Public URL of the post on instagram.com.
    var url: URL {
        URL(string: "https://www.instagram.com/\(kind == .reel ? "reel" : "p")/\(id)/")!
    }

    /// Formats a stat the way the website does: 4820 → "4.8K".
    static func format(count: Int) -> String {
        switch count {
        case 1_000_000...:
            return String(format: "%.1fM", Double(count) / 1_000_000)
                .replacingOccurrences(of: ".0M", with: "M")
        case 1_000...:
            return String(format: "%.1fK", Double(count) / 1_000)
                .replacingOccurrences(of: ".0K", with: "K")
        default:
            return String(count)
        }
    }
}
