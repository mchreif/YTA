import Foundation
import MapKit
import Observation
import SwiftUI

/// Presentation state and actions for the Connect screen.
@MainActor
@Observable
final class ConnectViewModel {

    /// Apple Maps link for the village in satellite view — the native
    /// equivalent of the website's Google Maps "Directions" link
    /// (which also opens satellite view, `t=k`).
    func directionsURL(for contact: ContactInfo) -> URL {
        var components = URLComponents(string: "https://maps.apple.com/")!
        components.queryItems = [
            URLQueryItem(name: "ll", value: "\(contact.coordinate.latitude),\(contact.coordinate.longitude)"),
            URLQueryItem(name: "q", value: "Yammouneh"),
            URLQueryItem(name: "t", value: "k")
        ]
        return components.url!
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
