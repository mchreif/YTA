import Foundation
import SwiftUI

/// The season a photograph shows — a presentation grouping only.
///
/// The assignment is visual (the photo's own content: ice, autumn
/// foliage, summer water); it invents no facts about Yammouneh.
enum ValleySeason: String, CaseIterable, Identifiable, Sendable {
    case summer
    case autumn
    case winter

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .summer: "Summer"
        case .autumn: "Autumn"
        case .winter: "Winter"
        }
    }
}

/// A photograph in the Yammouneh gallery — an "attraction scene" in the
/// Cinema of the Valley design.
struct GalleryPhoto: Identifiable, Hashable, Sendable {
    let id: String
    /// Two-digit ordinal shown in captions ("01" … "06").
    let number: String
    /// Official caption from ytalebanon.org, e.g. "Yammouneh River".
    let title: String
    /// Asset-catalog image name (official site photography).
    let imageName: String
    /// Season the photograph visibly depicts (presentation grouping).
    let season: ValleySeason
    /// The official mission program whose text tells this scene's story
    /// (only official YTA copy is ever shown — see ContentStore).
    let storyProgramID: String
}
