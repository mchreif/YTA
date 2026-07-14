import SwiftUI

/// Full-page hero with the looping village video, the serif tagline and
/// the two hero actions — a native recreation of the website's
/// full-viewport `yta-hero` stage. Fills whatever space its parent
/// proposes (the Home pager gives it the full screen).
struct HeroSection: View {

    /// Switches to the Yammouneh gallery tab (website: "Explore" → #yammouneh).
    let onExplore: () -> Void
    /// Opens the festival promo video (website: "Upcoming Event" modal).
    let onUpcomingEvent: () -> Void

    @Environment(ContentStore.self) private var content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var cueBouncing = false

    var body: some View {
        ZStack {
            background

            // Legibility gradient, dark at top and bottom like the website.
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.45), location: 0),
                    .init(color: .black.opacity(0.05), location: 0.4),
                    .init(color: .black.opacity(0.65), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack {
                Spacer()

                // Tagline block with the gold underline accent.
                VStack(spacing: 14) {
                    Text(content.heroTitle)
                        .font(YTAFont.display(38))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.4), radius: 8, y: 2)

                    LinearGradient(
                        colors: [.clear, .ytaGold, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 160, height: 2)
                }
                .padding(.horizontal, 28)
                .accessibilityAddTraits(.isHeader)

                Spacer()

                // Bottom block: welcome avatar, eyebrow, organization
                // name and actions — mirroring the website's hero stack.
                VStack(spacing: 12) {
                    HStack {
                        Spacer()
                        WelcomeAvatar()
                    }
                    .padding(.trailing, 6)

                    Text(content.heroEyebrow)
                        .font(YTAFont.semibold(11, relativeTo: .caption))
                        .kerning(2.5)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.ytaGold)

                    Text(content.organizationName)
                        .font(YTAFont.medium(13, relativeTo: .footnote))
                        .kerning(1.5)
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(0.85))

                    HStack(spacing: 12) {
                        Button(action: onExplore) {
                            Text("Explore")
                        }
                        .buttonStyle(YTASolidButtonStyle())

                        Button(action: onUpcomingEvent) {
                            Text("Upcoming Event")
                        }
                        .buttonStyle(YTAGlassButtonStyle())
                        .goldPulse()
                    }
                    .padding(.top, 6)

                    // Swipe-up cue — the native version of the website's
                    // "Scroll" indicator at the bottom of the hero.
                    Image(systemName: "chevron.compact.down")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .offset(y: cueBouncing ? 5 : -3)
                        .padding(.top, 4)
                        .accessibilityHidden(true)
                }
                .padding(.bottom, 12)
                .padding(.horizontal, 20)
            }
        }
        .clipped()
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                cueBouncing = true
            }
        }
    }

    /// The looping hero video, with the still poster as instant first frame
    /// and fallback (same poster image the website preloads).
    private var background: some View {
        // The poster sits in overlays of a clear base so the scaled-to-fill
        // image can never widen the layout beyond the proposed size.
        Color.clear
            .overlay {
                Image("hero-poster")
                    .resizable()
                    .scaledToFill()
            }
            .overlay {
                if let url = VideoLibrary.hero {
                    LoopingVideoView(url: url)
                }
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    HeroSection(onExplore: {}, onUpcomingEvent: {})
        .frame(height: 640)
        .environment(ContentStore())
}
