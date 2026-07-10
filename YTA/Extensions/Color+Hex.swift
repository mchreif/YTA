import SwiftUI
import UIKit

extension Color {

    /// Creates a color from a 24-bit RGB hex value, e.g. `Color(hex: 0x16A34A)`.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    /// Creates a dynamic color that resolves differently in light and dark mode.
    ///
    /// The website ships a light design only; the dark variants keep the same
    /// brand hues while moving surfaces onto the navy `#0f172a` family that the
    /// site already uses for its dark sections, so dark mode still feels "YTA".
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}
