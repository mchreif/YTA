import Foundation

/// A photograph in the Yammouneh gallery section.
struct GalleryPhoto: Identifiable, Hashable, Sendable {
    let id: String
    /// Two-digit ordinal shown in the caption ("01" … "06").
    let number: String
    /// Caption title, e.g. "Yammouneh River".
    let title: String
    /// Asset-catalog image name.
    let imageName: String
}
