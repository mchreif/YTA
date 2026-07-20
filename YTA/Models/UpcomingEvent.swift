import Foundation

/// The event promoted by the hero's "Upcoming Event" button.
///
/// Published the same way alerts and polls are — YTA edits one JSON file
/// on their own hosting, no app update needed (see `EventsStore`). The
/// button only lights up while at least one entry here is current, so it
/// never advertises an event that isn't actually happening.
struct UpcomingEvent: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let title: String
    /// When the event happens. `null` keeps the promotion open-ended —
    /// it stays current until removed.
    let date: Date?
    /// Where the button should take the user (the event's own page,
    /// tickets, festival announcement, etc). `null` falls back to the
    /// bundled festival promo video already shipped with the app.
    let linkURL: URL?

    /// Whether this entry should still count as "upcoming" —
    /// past-dated events are ignored automatically.
    var isCurrent: Bool {
        guard let date else { return true }
        return date > .now
    }
}
