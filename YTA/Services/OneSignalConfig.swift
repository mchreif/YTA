import Foundation

/// OneSignal project credentials.
///
/// `appID` comes from the OneSignal dashboard for **this** app —
/// Settings → Keys & IDs — after completing the one-time setup in
/// `Server/ADMIN-GUIDE.md` (create the app, upload an APNs auth key).
/// Push notifications silently do nothing until this placeholder is
/// replaced; nothing else in the app depends on it.
enum OneSignalConfig {
    static let appID = "REPLACE_WITH_ONESIGNAL_APP_ID"
}
