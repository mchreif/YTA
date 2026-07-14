import SwiftUI

// MARK: - Brand palette

/// Brand colors extracted 1:1 from the website's design tokens
/// (`--yta-sky`, `--yta-green`, `--yta-dark`, `--yta-gold`, `--yta-cream`).
/// Every color is dynamic so the app also looks correct in dark mode.
extension Color {

    /// Primary brand green — `#16a34a`.
    static let ytaGreen = Color(light: 0x16A34A, dark: 0x22C55E)

    /// Lighter green used for hovers / highlights — `#22c55e`.
    static let ytaGreenLight = Color(hex: 0x22C55E)

    /// Darker green used for pressed states — `#15803d`.
    static let ytaGreenDark = Color(hex: 0x15803D)

    /// Festival gold used for the event call-to-action — `#ffb41d`.
    static let ytaGold = Color(hex: 0xFFB41D)

    /// Deep navy used by the Impact section and footer — `#0f172a`.
    static let ytaNavy = Color(hex: 0x0F172A)

    /// Elevated surface on navy scenes (cards over the night ground).
    static let ytaNavyElevated = Color(hex: 0x16233B)

    /// Sky blue used by the nav bar and Connect section — `#d2edf9`.
    static let ytaSky = Color(light: 0xD2EDF9, dark: 0x13293A)

    /// App background — cream `#f7fbfd` in light, near-navy in dark.
    static let ytaBackground = Color(light: 0xF7FBFD, dark: 0x0B1220)

    /// Card / elevated surface color.
    static let ytaCard = Color(light: 0xFFFFFF, dark: 0x162032)

    /// Primary text — `#0f172a` on light backgrounds.
    static let ytaTextPrimary = Color(light: 0x0F172A, dark: 0xE8F1F8)

    /// Secondary text — `#6b7280` on light backgrounds.
    static let ytaTextSecondary = Color(light: 0x6B7280, dark: 0x94A3B8)

    /// Hairline borders — `#e5e7eb` on light backgrounds.
    static let ytaBorder = Color(light: 0xE5E7EB, dark: 0x243247)
}

// MARK: - Typography

/// Typography system matching the website:
/// Fraunces (italic serif) for display headings, Outfit for everything else.
/// All fonts scale with Dynamic Type via `relativeTo:`.
enum YTAFont {

    /// Light italic serif for hero-style display titles (Fraunces 300 italic).
    static func display(_ size: CGFloat, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        .custom("Fraunces-LightItalic", size: size, relativeTo: style)
    }

    /// Regular italic serif for medium display text (Fraunces 400 italic).
    static func displayRegular(_ size: CGFloat, relativeTo style: Font.TextStyle = .title) -> Font {
        .custom("Fraunces-Italic", size: size, relativeTo: style)
    }

    /// Semibold serif for strong editorial headings (Fraunces 600).
    static func heading(_ size: CGFloat, relativeTo style: Font.TextStyle = .title2) -> Font {
        .custom("Fraunces-SemiBold", size: size, relativeTo: style)
    }

    /// Semibold italic serif accent (Fraunces 600 italic).
    static func headingItalic(_ size: CGFloat, relativeTo style: Font.TextStyle = .title2) -> Font {
        .custom("Fraunces-SemiBoldItalic", size: size, relativeTo: style)
    }

    /// Body text (Outfit 400).
    static func body(_ size: CGFloat = 16, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom("Outfit-Regular", size: size, relativeTo: style)
    }

    /// Medium-weight UI text (Outfit 500).
    static func medium(_ size: CGFloat = 16, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom("Outfit-Medium", size: size, relativeTo: style)
    }

    /// Semibold labels and buttons (Outfit 600).
    static func semibold(_ size: CGFloat = 16, relativeTo style: Font.TextStyle = .headline) -> Font {
        .custom("Outfit-SemiBold", size: size, relativeTo: style)
    }

    /// Bold emphasis (Outfit 700).
    static func bold(_ size: CGFloat = 16, relativeTo style: Font.TextStyle = .headline) -> Font {
        .custom("Outfit-Bold", size: size, relativeTo: style)
    }
}

// MARK: - Metrics

/// Shared layout metrics matching the website's radii and spacing rhythm.
enum YTAMetrics {
    /// Large card corner radius (`--yta-radius: 20px`).
    static let radius: CGFloat = 20
    /// Small element corner radius (`--yta-radius-sm: 12px`).
    static let radiusSmall: CGFloat = 12
    /// Standard horizontal screen padding.
    static let gutter: CGFloat = 20
    /// Vertical rhythm between page sections.
    static let sectionSpacing: CGFloat = 48
}

// MARK: - Reusable styling

extension View {

    /// Standard elevated card styling used across the app.
    func ytaCardStyle(cornerRadius: CGFloat = YTAMetrics.radius) -> some View {
        self
            .background(Color.ytaCard)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.ytaBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }

    /// Reveal-on-scroll effect replicating the website's `data-yta-reveal`
    /// animation using the native scroll transition APIs.
    func ytaReveal() -> some View {
        scrollTransition(.animated(.spring(duration: 0.6, bounce: 0.2)).threshold(.visible(0.2))) { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0)
                .offset(y: phase.isIdentity ? 0 : 28)
                .scaleEffect(phase.isIdentity ? 1 : 0.96)
        }
    }
}
