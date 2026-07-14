import Foundation

/// Resolves the MP4 files bundled with the app.
///
/// All videos ship inside the app bundle (`Resources/Videos`), so playback
/// works fully offline. File names mirror the website's `assets/videos`.
enum VideoLibrary {

    /// Looping background video used by the hero section.
    static var hero: URL? { url(for: "hero") }

    /// The "Upcoming Event" promo (summer festival announcement).
    static var upcomingEvent: URL? { url(for: "summer-festival") }

    /// The hero welcome message from Ali Chreif
    /// (the website's `menhem-ios.mp4` avatar video).
    static var welcomeMessage: URL? { url(for: "welcome-message") }

    /// Resolves a bundled video by resource name (without extension).
    static func url(for resourceName: String) -> URL? {
        Bundle.main.url(forResource: resourceName, withExtension: "mp4")
    }
}
