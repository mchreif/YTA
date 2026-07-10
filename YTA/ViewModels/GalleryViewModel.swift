import Foundation
import Observation

/// Presentation state for the Yammouneh gallery screen,
/// including the full-screen lightbox (the native counterpart of the
/// website's `yta-lightbox`).
@MainActor
@Observable
final class GalleryViewModel {

    /// Photo currently open in the lightbox, `nil` when the grid is shown.
    var selectedPhoto: GalleryPhoto?

    /// Opens the lightbox for a photo.
    func open(_ photo: GalleryPhoto) {
        HapticsManager.tap()
        selectedPhoto = photo
    }

    /// Closes the lightbox.
    func close() {
        selectedPhoto = nil
    }

    /// Moves to the next / previous photo while the lightbox is open.
    /// - Parameters:
    ///   - direction: +1 for next, -1 for previous.
    ///   - photos: the ordered gallery collection.
    func step(_ direction: Int, in photos: [GalleryPhoto]) {
        guard
            let current = selectedPhoto,
            let index = photos.firstIndex(of: current)
        else { return }
        let next = index + direction
        guard photos.indices.contains(next) else { return }
        HapticsManager.selection()
        selectedPhoto = photos[next]
    }
}
