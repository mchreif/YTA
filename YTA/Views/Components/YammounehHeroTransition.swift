import SwiftUI

/// Cinematic full-width hero that dissolves seamlessly into the section
/// below it — built for the approved Yammouneh header artwork and reused
/// by any screen that opens on a scene.
///
/// Transition layers, bottom-up:
/// 1. The hero image (aspect-fill), with restrained parallax: it travels
///    slower than the content while scrolling and stretches gently on
///    overscroll.
/// 2. A scrim that deepens as the hero scrolls away, keeping any content
///    above it legible.
/// 3. The image-to-background dissolve: transparent over the upper image,
///    soft `fadeColor` from the lower-middle, and **exactly** `fadeColor`
///    at the bottom edge. The parent section uses the same color token as
///    its background, so there is no seam and no visible edge.
///
/// Reduce Motion: parallax, overscroll stretch and push-in are disabled;
/// the gradient dissolve (pure opacity layering) is preserved.
struct YammounehHeroTransition<Overlay: View>: View {

    /// Asset-catalog name of the approved hero artwork.
    let imageName: String
    /// Rendered height of the hero band.
    var height: CGFloat = 440
    /// The section background this hero dissolves into. Pass the same
    /// token the section uses — e.g. `.ytaJourneyBackground`.
    var fadeColor: Color = .ytaJourneyBackground
    /// Scroll offset from the owning ScrollView (0 at rest, positive when
    /// scrolled down, negative on overscroll). Drives the parallax.
    var scrollOffset: CGFloat = 0
    /// Whether the slow push-in plays while the hero is at rest.
    var pushIn = true
    /// Content anchored to the bottom of the hero (titles or controls
    /// when they are not already embedded in the artwork).
    @ViewBuilder var overlay: () -> Overlay

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let stretch = reduceMotion ? 0 : max(0, -scrollOffset)
        let recede = reduceMotion ? 0 : max(0, scrollOffset) * 0.38
        let departure = min(0.5, Double(max(0, scrollOffset)) / 460)

        ZStack(alignment: .bottom) {
            // 1 — the artwork, slower than the scroll, stretchy at rest.
            Color.clear
                .overlay {
                    Group {
                        if pushIn && !reduceMotion {
                            KenBurnsImage(imageName: imageName, duration: 24)
                        } else {
                            Image(imageName)
                                .resizable()
                                .scaledToFill()
                        }
                    }
                    .scaleEffect(1 + stretch / (height * 1.6), anchor: .top)
                    .offset(y: recede)
                }
                .clipped()

            // 2 — deepen while departing so overlaid content stays legible.
            fadeColor
                .opacity(departure)

            // 3 — the dissolve into the section background. The last stop
            // is the *exact* section token: no seam, no straight edge.
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: 0.48),
                    .init(color: fadeColor.opacity(0.45), location: 0.74),
                    .init(color: fadeColor.opacity(0.85), location: 0.9),
                    .init(color: fadeColor, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            overlay()
        }
        .frame(height: height)
        .accessibilityElement(children: .contain)
    }
}

/// Soft atmospheric continuation used at the top of a section that a
/// `YammounehHeroTransition` dissolves into: a faint gold glow and a
/// barely-there tonal shift so the ground never reads as flat paint —
/// while the junction row itself stays exactly the shared token.
struct JourneyAtmosphere: View {

    var body: some View {
        ZStack(alignment: .top) {
            // Tonal drift begins *below* the junction (top stays token).
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: 0.1),
                    .init(color: Color.black.opacity(0.16), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Restrained golden haze, echoing the artwork's warm light.
            RadialGradient(
                colors: [Color.ytaGold.opacity(0.055), .clear],
                center: .top,
                startRadius: 10,
                endRadius: 420
            )
            .frame(height: 460)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 0) {
            YammounehHeroTransition(imageName: "yammouneh-header") {
                EmptyView()
            }
            Color.ytaJourneyBackground
                .overlay(alignment: .top) { JourneyAtmosphere() }
                .frame(height: 500)
        }
    }
    .background(Color.ytaJourneyBackground)
    .ignoresSafeArea()
}
