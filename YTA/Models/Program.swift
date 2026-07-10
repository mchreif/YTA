import Foundation

/// One of the association's mission programs
/// (the six cards in the website's "Mission" section).
struct Program: Identifiable, Hashable, Sendable {
    let id: String
    /// Two-digit ordinal shown on the card ("01" … "06").
    let number: String
    let title: String
    let details: String
    /// Asset-catalog image name.
    let imageName: String
    /// Festival recap videos attached to this program (only the
    /// Music Festivals program has them — 2018, 2019 and 2023).
    let festivalVideos: [FestivalVideo]
}

/// A bundled festival recap video selectable from a program card.
struct FestivalVideo: Identifiable, Hashable, Sendable {
    /// Festival year, also used as the button label.
    let year: Int
    /// File name (without extension) of the bundled MP4.
    let resourceName: String

    var id: Int { year }
}
