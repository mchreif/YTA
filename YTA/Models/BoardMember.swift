import Foundation

/// A member of the YTA volunteer board.
struct BoardMember: Identifiable, Hashable, Sendable {
    let id: String
    /// Two-digit ordinal shown on the card ("01" … "05").
    let number: String
    let name: String
    let role: String
    /// Asset-catalog image name of the portrait.
    let imageName: String
}
