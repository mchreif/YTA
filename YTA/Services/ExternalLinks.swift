import Foundation

/// External destinations linked from the website.
///
/// Kept in one place so the app has a single audit point for
/// everything that leaves the app.
enum ExternalLinks {

    /// YTA on Instagram (@yta_leb).
    static let instagram = URL(string: "https://www.instagram.com/yta_leb?igsh=cXFxenI3ZzZ0a3d6&utm_source=qr")!

    /// YTA on Facebook.
    static let facebook = URL(string: "https://www.facebook.com/share/16XGVAATLb/?mibextid=wwXIfr")!

    /// The official website this app was built from.
    static let website = URL(string: "https://ytalebanon.org/")!

    /// Instagram handle displayed in the media section.
    static let instagramHandle = "yta_leb"

    /// Apple Maps link for a coordinate in satellite view — used by
    /// Connect and every attraction detail's Directions action
    /// (the site's Google link also opens satellite, `t=k`).
    static func appleMapsURL(latitude: Double, longitude: Double, label: String) -> URL {
        var components = URLComponents(string: "https://maps.apple.com/")!
        components.queryItems = [
            URLQueryItem(name: "ll", value: "\(latitude),\(longitude)"),
            URLQueryItem(name: "q", value: label),
            URLQueryItem(name: "t", value: "k")
        ]
        return components.url!
    }
}
