import SwiftUI

// MARK: - Scene title

/// Editorial heading used by the "Cinema of the Valley" design language:
/// an uppercase eyebrow, a serif italic title, and the gold accent rule.
/// Replaces the numbered web-style section chips on redesigned screens.
struct SceneTitle: View {

    let eyebrow: LocalizedStringKey
    let title: LocalizedStringKey
    var onDark = false
    var centered = true

    var body: some View {
        VStack(alignment: centered ? .center : .leading, spacing: 10) {
            Text(eyebrow)
                .font(YTAFont.semibold(11, relativeTo: .caption))
                .kerning(2.4)
                .textCase(.uppercase)
                .foregroundStyle(Color.ytaGold)

            Text(title)
                .font(YTAFont.display(30, relativeTo: .title))
                .foregroundStyle(onDark ? .white : Color.ytaTextPrimary)
                .multilineTextAlignment(centered ? .center : .leading)

            LinearGradient(
                colors: centered ? [.clear, .ytaGold, .clear] : [.ytaGold, .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 120, height: 2)
        }
        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Ken Burns

/// Slow cinematic push-in on a still photograph — the app's signature
/// image treatment. Static under Reduce Motion.
struct KenBurnsImage: View {

    /// Asset-catalog image name (official YTA photography only).
    let imageName: String
    /// Full push-in cycle length in seconds.
    var duration: Double = 16

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var zoomed = false

    var body: some View {
        Color.clear
            .overlay {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(zoomed ? 1.12 : 1.0, anchor: .init(x: 0.6, y: 0.4))
            }
            .clipped()
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    zoomed = true
                }
            }
            .accessibilityHidden(true)
    }
}

// MARK: - Scene scrim

/// The standard legibility gradient laid over full-bleed scenes:
/// dark at the base (where the serif caption sits), clear in the middle.
struct SceneScrim: View {

    var topOpacity = 0.35

    var body: some View {
        LinearGradient(
            stops: [
                .init(color: .black.opacity(topOpacity), location: 0),
                .init(color: .clear, location: 0.42),
                .init(color: Color.ytaNavy.opacity(0.88), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }
}

// MARK: - Awaiting official data

/// Honest-state card used wherever an official YTA asset is still
/// missing (e.g. the next festival date). Design principle from the
/// approved direction: show the true state, never fake data.
struct AwaitingDataCard: View {

    let headline: LocalizedStringKey
    let details: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Awaiting official announcement")
                .font(YTAFont.semibold(10, relativeTo: .caption2))
                .kerning(1.4)
                .textCase(.uppercase)
                .foregroundStyle(Color.ytaGold)

            Text(headline)
                .font(YTAFont.displayRegular(18, relativeTo: .title3))
                .foregroundStyle(.white)

            Text(details)
                .font(YTAFont.body(12, relativeTo: .caption))
                .foregroundStyle(.white.opacity(0.7))
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.ytaNavyElevated, in: RoundedRectangle(cornerRadius: YTAMetrics.radiusSmall + 4, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: YTAMetrics.radiusSmall + 4, style: .continuous)
                .strokeBorder(Color.ytaGold.opacity(0.35), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Route connector

/// A short segment of the gold "Roman road" that threads the Explore
/// journey together, drawn with a gentle S-curve and an end dot.
struct RouteConnector: View {

    /// Sways the curve left or right so consecutive segments alternate.
    var swayLeading = true
    var height: CGFloat = 44

    var body: some View {
        RouteCurve(swayLeading: swayLeading)
            .stroke(
                Color.ytaGold.opacity(0.85),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [1, 7])
            )
            .frame(height: height)
            .overlay(alignment: .bottom) {
                Circle()
                    .fill(Color.ytaGold)
                    .frame(width: 7, height: 7)
            }
            .accessibilityHidden(true)
    }

    private struct RouteCurve: Shape {
        let swayLeading: Bool

        func path(in rect: CGRect) -> Path {
            var path = Path()
            let sway: CGFloat = (swayLeading ? -1 : 1) * min(26, rect.width / 3)
            path.move(to: CGPoint(x: rect.midX, y: 0))
            path.addCurve(
                to: CGPoint(x: rect.midX, y: rect.height),
                control1: CGPoint(x: rect.midX + sway, y: rect.height * 0.35),
                control2: CGPoint(x: rect.midX - sway, y: rect.height * 0.65)
            )
            return path
        }
    }
}

#Preview("Scene components") {
    ScrollView {
        VStack(spacing: 30) {
            SceneTitle(eyebrow: "Bekaa Valley · Lebanon", title: "Explore Yammouneh")
            KenBurnsImage(imageName: "gallery-yam2")
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            RouteConnector()
            AwaitingDataCard(
                headline: "Summer festival — date to be announced",
                details: "The countdown and calendar actions activate when YTA publishes the official date."
            )
        }
        .padding()
    }
    .background(Color.ytaBackground)
}
