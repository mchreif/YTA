import Foundation

/// A key performance indicator in the "Our Impact" section.
struct ImpactStat: Identifiable, Hashable, Sendable {
    let id: String
    /// Final value the counter animates up to.
    let value: Int
    /// Suffix appended after the number (the site uses "+").
    let suffix: String
    /// Short label, e.g. "Festivals".
    let label: String
    /// One-sentence description below the label.
    let details: String
    /// SF Symbol representing the stat.
    let systemImage: String
}
