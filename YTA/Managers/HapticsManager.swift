import UIKit

/// Central place for triggering haptic feedback.
///
/// Generators are created lazily and reused, and `prepare()` is called before
/// each trigger so the Taptic Engine responds with minimal latency.
@MainActor
enum HapticsManager {

    private static let impactLight = UIImpactFeedbackGenerator(style: .light)
    private static let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    /// Light tap — used for card taps and small toggles.
    static func tap() {
        impactLight.prepare()
        impactLight.impactOccurred()
    }

    /// Medium impact — used for primary buttons and opening videos.
    static func impact() {
        impactMedium.prepare()
        impactMedium.impactOccurred()
    }

    /// Selection change — used when the gallery lightbox pages between photos.
    static func selection() {
        selectionGenerator.prepare()
        selectionGenerator.selectionChanged()
    }

    /// Success notification — used when a poll vote is recorded.
    static func success() {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.success)
    }
}
