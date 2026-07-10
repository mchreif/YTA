import Foundation
import UserNotifications

/// Local-notification support for community alerts.
///
/// Authorization is requested **provisionally**, so there is no permission
/// prompt — alerts arrive quietly in Notification Center until the user
/// promotes them. When background refresh discovers new alerts, one
/// notification per alert is delivered.
enum NotificationManager {

    /// Requests quiet, prompt-free notification delivery.
    static func requestProvisionalAuthorization() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound, .provisional])
    }

    /// Delivers a local notification for each newly discovered alert.
    static func notify(about alerts: [CommunityAlert]) async {
        let center = UNUserNotificationCenter.current()
        for alert in alerts {
            let content = UNMutableNotificationContent()
            content.title = alert.title
            content.body = alert.message
            content.sound = alert.severity == .urgent ? .default : nil
            let request = UNNotificationRequest(
                identifier: "yta-alert-\(alert.id)",
                content: content,
                trigger: nil
            )
            try? await center.add(request)
        }
    }
}
