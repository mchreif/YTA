import SwiftUI

/// Section heading matching the website's `yta-section-head`:
/// a two-digit ordinal chip, an uppercase green kicker title,
/// and an optional serif subtitle.
struct SectionHeader: View {

    /// Two-digit section number, e.g. "01".
    let number: String
    /// Uppercase kicker, e.g. "Mission".
    let title: LocalizedStringKey
    /// Optional descriptive subtitle, e.g. "Leadership & Governance".
    var subtitle: LocalizedStringKey?
    /// Set for sections rendered on dark backgrounds (Impact).
    var onDark = false

    var body: some View {
        VStack(spacing: 10) {
            Text(number)
                .font(YTAFont.semibold(13, relativeTo: .caption))
                .foregroundStyle(Color.ytaGold)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    Capsule().strokeBorder(Color.ytaGold.opacity(0.45), lineWidth: 1)
                )

            Text(title)
                .font(YTAFont.bold(24, relativeTo: .title2))
                .textCase(.uppercase)
                .kerning(2.2)
                .foregroundStyle(Color.ytaGreen)
                .multilineTextAlignment(.center)

            if let subtitle {
                Text(subtitle)
                    .font(YTAFont.displayRegular(22, relativeTo: .title3))
                    .foregroundStyle(onDark ? Color.white : Color.ytaTextPrimary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 40) {
        SectionHeader(number: "01", title: "Mission")
        SectionHeader(number: "03", title: "Board Members", subtitle: "Leadership & Governance")
    }
    .padding()
    .background(Color.ytaBackground)
}
