import UIKit
import OneSignalFramework

/// Bridges OneSignal's SDK startup, which must happen from
/// `application(_:didFinishLaunchingWithOptions:)` — the one launch hook
/// SwiftUI's `App` protocol doesn't expose on its own. Wired in via
/// `@UIApplicationDelegateAdaptor` in `YTAApp`.
final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Skipped until a real OneSignal App ID is configured, so an
        // unconfigured build never talks to OneSignal's servers.
        guard OneSignalConfig.appID != "REPLACE_WITH_ONESIGNAL_APP_ID" else { return true }

        OneSignal.initialize(OneSignalConfig.appID, withLaunchOptions: launchOptions)
        return true
    }
}
