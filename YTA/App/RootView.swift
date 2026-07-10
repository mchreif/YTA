import SwiftUI

/// The five top-level destinations of the app.
///
/// They mirror the website's navigation with one native addition:
/// Mission, Impact and Board share the Home tab (as they share the
/// website's landing page); Instagram and Press share the Media tab;
/// Community hosts the app-exclusive alerts and polls.
enum AppTab: String, CaseIterable, Identifiable {
    case home
    case yammouneh
    case community
    case media
    case connect

    var id: String { rawValue }

    /// Localized tab title.
    var title: LocalizedStringKey {
        switch self {
        case .home:      "Home"
        case .yammouneh: "Yammouneh"
        case .community: "Community"
        case .media:     "Media"
        case .connect:   "Connect"
        }
    }

    /// SF Symbol shown in the tab bar.
    var systemImage: String {
        switch self {
        case .home:      "house.fill"
        case .yammouneh: "photo.on.rectangle.angled"
        case .community: "megaphone.fill"
        case .media:     "play.rectangle.on.rectangle.fill"
        case .connect:   "location.circle.fill"
        }
    }
}

/// Root container: animated splash intro, then the tab bar.
/// Also resolves deep links and schedules background refresh.
///
/// Deep links use the scheme registered in Info.plist, e.g.
/// `ytalebanon://alerts`, `ytalebanon://polls`, `ytalebanon://yammouneh`.
struct RootView: View {

    @Environment(CommunityStore.self) private var community
    @Environment(\.scenePhase) private var scenePhase

    @State private var selection: AppTab = .home
    @State private var isShowingSplash = true

    var body: some View {
        ZStack {
            tabs

            if isShowingSplash {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        isShowingSplash = false
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 1.06)))
                .zIndex(1)
            }
        }
        .task {
            // Warm up quietly behind the splash: community content and
            // prompt-free (provisional) notification permission.
            await NotificationManager.requestProvisionalAuthorization()
            await community.loadIfNeeded()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                CommunityBackgroundRefresh.schedule()
            }
        }
        .onOpenURL { url in
            guard let target = Self.destination(for: url) else { return }
            selection = target.tab
            if let segment = target.segment {
                community.requestedSegment = segment
            }
        }
    }

    private var tabs: some View {
        TabView(selection: $selection) {
            Tab(AppTab.home.title, systemImage: AppTab.home.systemImage, value: AppTab.home) {
                HomeView(
                    onExplore: { selection = .yammouneh },
                    onOpenAlerts: {
                        community.requestedSegment = .alerts
                        selection = .community
                    }
                )
            }
            Tab(AppTab.yammouneh.title, systemImage: AppTab.yammouneh.systemImage, value: AppTab.yammouneh) {
                GalleryView()
            }
            Tab(AppTab.community.title, systemImage: AppTab.community.systemImage, value: AppTab.community) {
                CommunityView()
            }
            .badge(community.unreadAlertCount)
            Tab(AppTab.media.title, systemImage: AppTab.media.systemImage, value: AppTab.media) {
                MediaHubView()
            }
            Tab(AppTab.connect.title, systemImage: AppTab.connect.systemImage, value: AppTab.connect) {
                ConnectView()
            }
        }
    }

    /// Maps an incoming URL onto a tab (and optionally a Community segment).
    ///
    /// Website anchors (`#programs`, `#board`, …) map to their native home.
    static func destination(for url: URL) -> (tab: AppTab, segment: CommunityStore.Segment?)? {
        let target = (url.host() ?? url.lastPathComponent).lowercased()
        switch target {
        case "home", "hero":                           return (.home, nil)
        case "mission", "programs", "impact", "board": return (.home, nil)
        case "yammouneh", "gallery":                   return (.yammouneh, nil)
        case "community":                              return (.community, nil)
        case "alerts":                                 return (.community, .alerts)
        case "polls":                                  return (.community, .polls)
        case "media", "instagram", "press", "news":    return (.media, nil)
        case "connect", "contact":                     return (.connect, nil)
        default:                                       return nil
        }
    }
}

#Preview {
    RootView()
        .environment(ContentStore())
        .environment(CommunityStore())
}
