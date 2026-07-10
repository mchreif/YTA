import Foundation
import CoreLocation

/// Contact and location details for the association,
/// mirroring the website's "Connect" section and structured data.
struct ContactInfo: Sendable {
    let phoneDisplay: String
    let phoneURL: URL
    let email: String
    let emailURL: URL
    /// Mail link pre-filled with the "Visit Yammouneh" subject,
    /// matching the website's "Request a Trip Guide" action.
    let tripGuideURL: URL
    let addressLine: String
    /// Yammouneh's coordinates (from the site's geo metadata: 34.0042, 36.0428).
    let coordinate: CLLocationCoordinate2D
    /// Quick stats shown next to the actions (value, label).
    let quickStats: [QuickStat]

    /// A small headline stat like "84+ Natural springs".
    struct QuickStat: Identifiable, Hashable, Sendable {
        let value: String
        let label: String
        var id: String { label }
    }
}
