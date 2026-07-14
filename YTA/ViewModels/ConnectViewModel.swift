import Foundation
import MapKit
import Observation
import SwiftUI

/// Presentation state and actions for the Connect screen.
@MainActor
@Observable
final class ConnectViewModel {

    /// Apple Maps link for the village in satellite view — the native
    /// equivalent of the website's Google Maps "Directions" link.
    func directionsURL(for contact: ContactInfo) -> URL {
        ExternalLinks.appleMapsURL(
            latitude: contact.coordinate.latitude,
            longitude: contact.coordinate.longitude,
            label: "Yammouneh"
        )
    }

    /// Initial camera for the embedded map: centered on Yammouneh at a
    /// zoom comparable to the website's embed (z≈14).
    func cameraPosition(for contact: ContactInfo) -> MapCameraPosition {
        .region(
            MKCoordinateRegion(
                center: contact.coordinate,
                latitudinalMeters: 6_000,
                longitudinalMeters: 6_000
            )
        )
    }
}
