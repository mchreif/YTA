import Foundation
import BackgroundTasks

/// Periodic background check of the alerts feed, so users learn about new
/// announcements without opening the app.
///
/// Registered via the `.backgroundTask(.appRefresh(...))` scene modifier in
/// `YTAApp` and permitted through `BGTaskSchedulerPermittedIdentifiers`
/// in Info.plist. iOS decides the exact cadence; the app requests a run
/// no sooner than every four hours.
enum CommunityBackgroundRefresh {

    /// Task identifier — must match Info.plist.
    static let taskIdentifier = "org.ytalebanon.app.refresh"

    private static let knownAlertsKey = "yta.known-alert-ids"

    /// Asks the system for the next background refresh slot.
    /// Called whenever the app moves to the background.
    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 4 * 60 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    /// Fetches the feed, notifies about alerts not seen before, and
    /// schedules the next run. Safe to call from any context.
    static func run() async {
        schedule()

        let api = CommunityAPI()
        guard let alerts = try? await api.fetchAlerts() else { return }

        let defaults = UserDefaults.standard
        let known = Set(defaults.stringArray(forKey: knownAlertsKey) ?? [])

        // First run: don't notify about the entire backlog.
        guard !known.isEmpty else {
            defaults.set(alerts.map(\.id), forKey: knownAlertsKey)
            return
        }

        let fresh = alerts.filter { !known.contains($0.id) }
        guard !fresh.isEmpty else { return }

        await NotificationManager.notify(about: fresh)
        defaults.set(alerts.map(\.id), forKey: knownAlertsKey)
    }
}
