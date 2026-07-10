import SwiftUI

/// Application entry point for the Yammouneh Tourism Association (YTA) app.
///
/// The app is a fully native SwiftUI recreation of https://ytalebanon.org,
/// extended with live community features (broadcast alerts and project
/// polls) fed from the association's own web hosting. Website content is
/// bundled and works completely offline; the community feed caches its
/// last successful sync.
@main
struct YTAApp: App {

    /// Single source of truth for all website-derived content.
    @State private var content = ContentStore()

    /// Live community content: alerts and polls.
    @State private var community = CommunityStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(content)
                .environment(community)
                .tint(.ytaGreen)
        }
        .backgroundTask(.appRefresh(CommunityBackgroundRefresh.taskIdentifier)) {
            await CommunityBackgroundRefresh.run()
        }
    }
}
