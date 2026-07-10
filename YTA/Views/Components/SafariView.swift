import SwiftUI
import SafariServices

/// In-app Safari browser used to read press articles without
/// leaving the app.
struct SafariView: UIViewControllerRepresentable {

    /// The web page to open.
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.barCollapsingEnabled = true
        let controller = SFSafariViewController(url: url, configuration: configuration)
        controller.preferredControlTintColor = UIColor(Color.ytaGreen)
        controller.dismissButtonStyle = .close
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // The URL is fixed for the lifetime of the sheet; nothing to update.
    }
}
