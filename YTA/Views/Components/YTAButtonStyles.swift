import SwiftUI

/// Solid brand-green button, the native version of the website's
/// `.yta-btn-solid`. Presses scale down with a spring and fire a haptic.
struct YTASolidButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(YTAFont.semibold(14, relativeTo: .callout))
            .kerning(1.2)
            .textCase(.uppercase)
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 13)
            .background(
                Capsule().fill(configuration.isPressed ? Color.ytaGreenDark : Color.ytaGreen)
            )
            .shadow(color: Color.ytaGreen.opacity(0.35), radius: 10, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(duration: 0.25), value: configuration.isPressed)
    }
}

/// Frosted "glass" button matching the website's `.yta-btn-glass`,
/// used over the hero video.
struct YTAGlassButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(YTAFont.semibold(14, relativeTo: .callout))
            .kerning(1.2)
            .textCase(.uppercase)
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 13)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule().strokeBorder(.white.opacity(0.5), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(duration: 0.25), value: configuration.isPressed)
    }
}

/// Pulsing gold glow replicating the website's `flash-btn` keyframe
/// animation on the "Upcoming Event" button. Honors Reduce Motion.
struct GoldPulse: ViewModifier {

    /// Whether the glow should run at all — off while the button it
    /// decorates has nothing live to promote.
    var isActive: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    func body(content: Content) -> some View {
        content
            .shadow(
                color: Color.ytaGold.opacity(isActive && !pulsing ? 0.55 : 0),
                radius: pulsing ? 18 : 2
            )
            .onChange(of: isActive, initial: true) {
                guard isActive, !reduceMotion else {
                    pulsing = false
                    return
                }
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: false)) {
                    pulsing = true
                }
            }
    }
}

extension View {
    /// Applies the festival-gold pulsing glow. Pass `isActive: false` to
    /// suppress it entirely (e.g. while the button it decorates is
    /// disabled).
    func goldPulse(isActive: Bool = true) -> some View {
        modifier(GoldPulse(isActive: isActive))
    }
}
