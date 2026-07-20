import SwiftUI

/// Application entry point for the Yammouneh Tourism Association (YTA) app.
///
/// The app is a fully native SwiftUI recreation of https://ytalebanon.org,
/// extended with live content fed from the association's own web hosting:
/// broadcast alerts, project polls, and press articles. Website content is
/// bundled and works completely offline; the live feeds cache their last
/// successful sync.
@main
struct YTAApp: App {

    /// Bridges OneSignal's SDK startup — see `AppDelegate`.
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    /// Single source of truth for all website-derived content.
    @State private var content = ContentStore()

    /// Live community content: alerts and polls.
    @State private var community = CommunityStore()

    /// Live press articles (Press tab).
    @State private var news = NewsStore()

    /// Live "Upcoming Event" promotion (Home hero button).
    @State private var events = EventsStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(content)
                .environment(community)
                .environment(news)
                .environment(events)
                .tint(.ytaGreen)
        }
        .backgroundTask(.appRefresh(CommunityBackgroundRefresh.taskIdentifier)) {
            await CommunityBackgroundRefresh.run()
        }
    }
}
