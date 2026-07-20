import SwiftUI

/// The landing screen — four full-screen pages with vertical snap paging,
/// exactly like the website's full-viewport sections:
/// Hero → 01 Mission → 02 Impact → 03 Board.
///
/// A capsule page indicator floats at the trailing edge; the alerts bell
/// floats top-trailing.
struct HomeView: View {

    /// Invoked when the user taps "Explore" in the hero,
    /// switching to the Yammouneh gallery tab.
    let onExplore: () -> Void

    /// Invoked when the user taps the alerts bell,
    /// switching to the Community tab's alerts feed.
    let onOpenAlerts: () -> Void

    /// Invoked by the closing "Plan your visit" banner,
    /// switching to the Connect tab.
    let onPlanVisit: () -> Void

    @Environment(ContentStore.self) private var content
    @Environment(CommunityStore.self) private var community
    @Environment(EventsStore.self) private var events
    @Environment(\.openURL) private var openURL
    @State private var viewModel = HomeViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack(alignment: .topTrailing) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    heroPage
                        .id(HomePage.hero)

                    MissionSection(onPlayFestival: { viewModel.play($0) })
                        .containerRelativeFrame(.vertical)
                        .background(Color.ytaBackground)
                        .id(HomePage.mission)

                    ImpactSection(
                        countersArmed: viewModel.impactCountersArmed,
                        onBecameVisible: { viewModel.impactBecameVisible() }
                    )
                    .containerRelativeFrame(.vertical)
                    .id(HomePage.impact)

                    BoardSection(onPlanVisit: onPlanVisit)
                        .containerRelativeFrame(.vertical)
                        .background(Color.ytaBackground)
                        .id(HomePage.board)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $viewModel.currentPage)
            .scrollIndicators(.hidden)
            .background(Color.ytaBackground)
            .ignoresSafeArea(edges: .top)

            alertsBell
                .padding(.top, 6)
                .padding(.trailing, 16)
        }
        .overlay(alignment: .trailing) {
            pageIndicator
                .padding(.trailing, 6)
        }
        .onChange(of: viewModel.currentPage) { _, page in
            if page == .impact {
                viewModel.impactBecameVisible()
            }
        }
        .fullScreenCover(isPresented: $viewModel.isShowingEventVideo) {
            eventVideoPlayer
        }
        .fullScreenCover(item: $viewModel.activeFestivalVideo) { video in
            festivalPlayer(for: video)
        }
        .task {
            await events.loadIfNeeded()
        }
    }

    /// Page one: the full-bleed hero video with the "Discover" ticker
    /// anchored at the bottom, exactly like the website's hero stage.
    private var heroPage: some View {
        VStack(spacing: 0) {
            HeroSection(
                onExplore: onExplore,
                onUpcomingEvent: { openActiveEvent() },
                isUpcomingEventActive: events.hasUpcomingEvent
            )
            TickerView(items: content.tickerItems)
        }
        .containerRelativeFrame(.vertical)
    }

    /// Trailing capsule dots — tap to jump straight to a page.
    private var pageIndicator: some View {
        VStack(spacing: 10) {
            ForEach(HomePage.allCases) { page in
                Button {
                    viewModel.goTo(page)
                } label: {
                    Capsule()
                        .fill(
                            viewModel.currentPage == page
                                ? Color.ytaGreen
                                : Color.ytaTextSecondary.opacity(0.4)
                        )
                        .frame(width: 6, height: viewModel.currentPage == page ? 22 : 6)
                }
                .accessibilityLabel(page.title)
                .accessibilityAddTraits(viewModel.currentPage == page ? .isSelected : [])
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 5)
        .background(.ultraThinMaterial, in: Capsule())
        .animation(.spring(duration: 0.4), value: viewModel.currentPage)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Page indicator")
    }

    /// Floating alerts bell with the unread badge; bounces when new
    /// alerts arrive.
    private var alertsBell: some View {
        Button {
            HapticsManager.tap()
            onOpenAlerts()
        } label: {
            Image(systemName: community.unreadAlertCount > 0 ? "bell.badge.fill" : "bell.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white, Color.ytaGold)
                .symbolEffect(.bounce, value: community.unreadAlertCount)
                .padding(12)
                .background(.black.opacity(0.35), in: Circle())
                .overlay(alignment: .topTrailing) {
                    if community.unreadAlertCount > 0 {
                        Text("\(community.unreadAlertCount)")
                            .font(YTAFont.bold(11, relativeTo: .caption2))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: 0xDC2626), in: Capsule())
                            .offset(x: 5, y: -4)
                    }
                }
        }
        .accessibilityLabel(
            community.unreadAlertCount > 0
                ? "Alerts, \(community.unreadAlertCount) unread"
                : "Alerts"
        )
    }

    /// Routes the "Upcoming Event" tap to wherever YTA published it:
    /// their own link if given, otherwise the bundled promo video.
    /// Only reachable while `events.hasUpcomingEvent` is true, since the
    /// button is disabled otherwise.
    private func openActiveEvent() {
        if let link = events.activeEvent?.linkURL {
            HapticsManager.impact()
            openURL(link)
        } else {
            viewModel.showEventVideo()
        }
    }

    /// Player for the "Upcoming Event" promo.
    @ViewBuilder
    private var eventVideoPlayer: some View {
        if let url = VideoLibrary.upcomingEvent {
            VideoPlayerSheet(title: String(localized: "Upcoming Event"), url: url)
        } else {
            missingVideoFallback
        }
    }

    /// Player for a festival recap year.
    @ViewBuilder
    private func festivalPlayer(for video: FestivalVideo) -> some View {
        if let url = VideoLibrary.url(for: video.resourceName) {
            VideoPlayerSheet(title: "Yammouneh Festival \(video.year)", url: url)
        } else {
            missingVideoFallback
        }
    }

    /// Shown only if a bundled video resource cannot be resolved,
    /// which indicates a build misconfiguration rather than a user error.
    private var missingVideoFallback: some View {
        VStack {
            ContentUnavailableView(
                "Video Unavailable",
                systemImage: "video.slash",
                description: Text("This video could not be loaded from the app bundle.")
            )
            Button("Dismiss") {
                viewModel.isShowingEventVideo = false
                viewModel.activeFestivalVideo = nil
            }
            .buttonStyle(YTASolidButtonStyle())
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    HomeView(onExplore: {}, onOpenAlerts: {}, onPlanVisit: {})
        .environment(ContentStore())
        .environment(CommunityStore())
        .environment(EventsStore())
}
