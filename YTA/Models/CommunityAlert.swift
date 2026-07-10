import Foundation

/// An announcement broadcast to every app user.
///
/// Alerts are published by the YTA admin as JSON at
/// `https://ytalebanon.org/app/alerts.json` (see `Server/` in the project
/// root for the ready-to-upload files and the admin guide). The app polls
/// the feed on launch, on pull-to-refresh, and via background refresh —
/// new alerts surface as local notifications and an unread badge.
struct CommunityAlert: Identifiable, Codable, Hashable, Sendable {

    /// Visual urgency of the alert.
    enum Severity: String, Codable, Sendable {
        /// General information (sky blue).
        case info
        /// Festival / activity announcements (gold).
        case event
        /// Time-critical notices (red).
        case urgent
    }

    /// Stable identifier — reusing an id replaces the alert for users.
    let id: String
    let title: String
    let message: String
    let severity: Severity
    /// Publication date (ISO 8601 in the feed).
    let date: Date
    /// Optional "learn more" destination.
    let linkURL: URL?

    /// SF Symbol for the severity.
    var systemImage: String {
        switch severity {
        case .info:   "info.circle.fill"
        case .event:  "sparkles"
        case .urgent: "exclamationmark.triangle.fill"
        }
    }
}
