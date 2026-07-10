import Foundation
import Observation

/// Presentation state for the Media (Instagram) screen.
@MainActor
@Observable
final class MediaViewModel {

    /// Identifier of the post currently centered in the carousel.
    /// Drives the coverflow focus effect, mirroring the website's
    /// `is-focus` carousel state.
    var focusedPostID: String?

    /// Registers a card tap before the system opens Instagram.
    func willOpenPost() {
        HapticsManager.tap()
    }
}
