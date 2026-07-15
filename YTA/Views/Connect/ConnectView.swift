import SwiftUI
import MapKit

/// The "07 · Connect" tab — contact actions, quick stats, the satellite
/// map of Yammouneh, social links and the footer, recreating the
/// website's Connect section end to end.
struct ConnectView: View {

    @Environment(ContentStore.self) private var content
    @Environment(\.openURL) private var openURL
    @State private var viewModel = ConnectViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                sceneBanner

                Text(content.connectLead)
                    .font(YTAFont.body(15, relativeTo: .subheadline))
                    .foregroundStyle(Color.ytaTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: 620)
                    .padding(.horizontal, YTAMetrics.gutter)

                actionChips
                map
                quickStats
                socialRow
                planVisitCard
                footer
            }
        }
        .background(
            // The website paints Connect over a soft sky gradient.
            LinearGradient(
                colors: [Color.ytaBackground, Color.ytaSky, Color.ytaBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .ignoresSafeArea(edges: .top)
        .scrollIndicators(.hidden)
    }

    // MARK: Scene banner

    /// Cinematic opener for the visit screen — the reserve photograph
    /// (site gallery, official caption "Natural Reserve") as a full-width
    /// hero dissolving into this screen's background, matching the
    /// Explore transition language.
    private var sceneBanner: some View {
        YammounehHeroTransition(
            imageName: "gallery-yam8",
            height: 264,
            fadeColor: .ytaBackground
        ) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Visit Yammouneh · Partner with YTA")
                    .font(YTAFont.semibold(10, relativeTo: .caption))
                    .kerning(1.8)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.ytaGold)
                Text("Plan Your Visit")
                    .font(YTAFont.display(30, relativeTo: .title))
                    .foregroundStyle(.white)
            }
            .shadow(color: .black.opacity(0.55), radius: 6, y: 1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, YTAMetrics.gutter)
            .padding(.bottom, 62)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: Contact actions

    /// Call / Email / Directions chips (`yta-connect-chip` on the website).
    private var actionChips: some View {
        VStack(spacing: 12) {
            ContactChip(
                systemName: "phone.fill",
                title: "Call us",
                detail: content.contact.phoneDisplay
            ) {
                HapticsManager.tap()
                openURL(content.contact.phoneURL)
            }

            ContactChip(
                systemName: "envelope.fill",
                title: "Email",
                detail: content.contact.email
            ) {
                HapticsManager.tap()
                openURL(content.contact.emailURL)
            }

            ContactChip(
                systemName: "location.fill",
                title: "Directions",
                detail: content.contact.addressLine
            ) {
                HapticsManager.tap()
                openURL(viewModel.directionsURL(for: content.contact))
            }
        }
        .padding(.horizontal, YTAMetrics.gutter)
    }

    // MARK: Map

    /// Satellite map centered on the village — the native counterpart of
    /// the site's Google Maps embed (which also uses satellite view).
    private var map: some View {
        Map(initialPosition: viewModel.cameraPosition(for: content.contact)) {
            Marker("Yammouneh", systemImage: "leaf.fill", coordinate: content.contact.coordinate)
                .tint(Color.ytaGreen)
        }
        .mapStyle(.hybrid(elevation: .realistic))
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: YTAMetrics.radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: YTAMetrics.radius, style: .continuous)
                .strokeBorder(Color.ytaBorder, lineWidth: 1)
        )
        .padding(.horizontal, YTAMetrics.gutter)
        .accessibilityLabel("Map of Yammouneh, Bekaa Valley, Lebanon")
    }

    // MARK: Stats

    /// "24h response / 84+ springs / Year-round eco-tourism" stat band.
    private var quickStats: some View {
        HStack(spacing: 0) {
            ForEach(content.contact.quickStats) { stat in
                VStack(spacing: 4) {
                    Text(stat.value)
                        .font(YTAFont.bold(18, relativeTo: .headline))
                        .foregroundStyle(Color.ytaGreen)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(stat.label)
                        .font(YTAFont.medium(12, relativeTo: .caption))
                        .foregroundStyle(Color.ytaTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.vertical, 18)
        .ytaCardStyle()
        .padding(.horizontal, YTAMetrics.gutter)
    }

    // MARK: Social

    /// "Follow YTA" row with Instagram, Facebook and a share action.
    private var socialRow: some View {
        HStack(spacing: 14) {
            Text("Follow YTA")
                .font(YTAFont.semibold(13, relativeTo: .caption))
                .kerning(1.2)
                .textCase(.uppercase)
                .foregroundStyle(Color.ytaTextSecondary)

            Spacer()

            socialButton(systemName: "camera.circle.fill", label: "Instagram", url: ExternalLinks.instagram)
            socialButton(systemName: "hand.thumbsup.circle.fill", label: "Facebook", url: ExternalLinks.facebook)

            ShareLink(item: ExternalLinks.website) {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color.ytaGreen, Color.ytaGreen.opacity(0.15))
            }
            .accessibilityLabel("Share the YTA website")
        }
        .padding(.horizontal, YTAMetrics.gutter + 4)
    }

    private func socialButton(systemName: String, label: String, url: URL) -> some View {
        Button {
            HapticsManager.tap()
            openURL(url)
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 30))
                .foregroundStyle(Color.ytaGreen, Color.ytaGreen.opacity(0.15))
        }
        .accessibilityLabel("YTA on \(label)")
    }

    // MARK: Plan your visit

    /// "Plan Your Visit" card with the trip-guide mail action.
    private var planVisitCard: some View {
        VStack(spacing: 10) {
            Text("Plan Your Visit")
                .font(YTAFont.headingItalic(24, relativeTo: .title2))
                .foregroundStyle(.white)

            Text("Ask us about routes, guided tours, festival dates, and local recommendations.")
                .font(YTAFont.body(14, relativeTo: .subheadline))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            Button {
                HapticsManager.impact()
                openURL(content.contact.tripGuideURL)
            } label: {
                Text("Request a Trip Guide")
            }
            .buttonStyle(YTASolidButtonStyle())
            .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.ytaNavy, Color(hex: 0x14532D)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: YTAMetrics.radius, style: .continuous)
        )
        .padding(.horizontal, YTAMetrics.gutter)
    }

    // MARK: Footer

    /// Footer matching the website: organization, region and copyright.
    private var footer: some View {
        VStack(spacing: 6) {
            Image("logo-yta")
                .resizable()
                .scaledToFit()
                .frame(height: 44)

            Text(content.organizationName)
                .font(YTAFont.semibold(14, relativeTo: .footnote))
                .foregroundStyle(Color.ytaTextPrimary)

            Text(content.heroEyebrow)
                .font(YTAFont.body(12, relativeTo: .caption))
                .foregroundStyle(Color.ytaTextSecondary)

            Text(content.copyright)
                .font(YTAFont.body(12, relativeTo: .caption))
                .foregroundStyle(Color.ytaTextSecondary)
                .padding(.top, 8)
        }
        .padding(.top, 10)
        .padding(.bottom, YTAMetrics.sectionSpacing)
    }
}

/// A tappable contact chip with icon, bold action and detail line.
private struct ContactChip: View {

    let systemName: String
    let title: LocalizedStringKey
    let detail: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.ytaGreen)
                    .frame(width: 46, height: 46)
                    .background(Color.ytaGreen.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(YTAFont.semibold(15, relativeTo: .headline))
                        .foregroundStyle(Color.ytaTextPrimary)
                    Text(detail)
                        .font(YTAFont.body(14, relativeTo: .subheadline))
                        .foregroundStyle(Color.ytaTextSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.ytaTextSecondary.opacity(0.6))
            }
            .padding(14)
            .ytaCardStyle(cornerRadius: YTAMetrics.radiusSmall + 4)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ConnectView()
        .environment(ContentStore())
}
