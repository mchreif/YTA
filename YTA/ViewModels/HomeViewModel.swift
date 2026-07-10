import Foundation
import Observation
import SwiftUI

/// The four full-screen pages of the Home tab, in vertical swipe order —
/// matching the website where hero, mission, impact and board are each a
/// full-viewport section of the landing page.
enum HomePage: Int, CaseIterable, Identifiable {
    case hero
    case mission
    case impact
    case board

    var id: Int { rawValue }

    /// Accessible name, also used by the page indicator.
    var title: LocalizedStringKey {
        switch self {
        case .hero:    "Overview"
        case .mission: "Mission"
        case .impact:  "Our Impact"
        case .board:   "Board Members"
        }
    }
}

/// Presentation state for the Home screen
/// (hero, mission, impact and board pages).
@MainActor
@Observable
final class HomeViewModel {

    /// The page currently snapped into view.
    var currentPage: HomePage? = .hero

    /// Festival recap video currently playing full screen, if any.
    var activeFestivalVideo: FestivalVideo?

    /// Whether the "Upcoming Event" promo video is presented.
    var isShowingEventVideo = false

    /// Set to `true` once the impact page is reached, which starts the
    /// KPI count-up animation (mirrors the website's
    /// intersection-observer trigger).
    var impactCountersArmed = false

    /// Presents the promo video full screen.
    func showEventVideo() {
        HapticsManager.impact()
        isShowingEventVideo = true
    }

    /// Presents a festival recap video (2018 / 2019 / 2023) full screen.
    func play(_ video: FestivalVideo) {
        HapticsManager.impact()
        activeFestivalVideo = video
    }

    /// Arms the impact counters the first time the page becomes visible.
    func impactBecameVisible() {
        guard !impactCountersArmed else { return }
        impactCountersArmed = true
    }

    /// Snaps to a page (used by the page indicator dots).
    func goTo(_ page: HomePage) {
        HapticsManager.selection()
        withAnimation(.spring(duration: 0.55)) {
            currentPage = page
        }
    }
}
