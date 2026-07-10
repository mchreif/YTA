import Foundation
import Observation

/// Presentation state for the Press screen.
@MainActor
@Observable
final class PressViewModel {

    /// Article currently open in the in-app browser, `nil` when browsing the list.
    var articleInBrowser: NewsArticle?

    /// Opens an article in the in-app Safari sheet.
    func read(_ article: NewsArticle) {
        HapticsManager.tap()
        articleInBrowser = article
    }
}
