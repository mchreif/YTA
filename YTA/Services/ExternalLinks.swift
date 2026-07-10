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
}
