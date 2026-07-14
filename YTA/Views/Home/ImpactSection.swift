import SwiftUI

/// The "02 · Our Impact" full page on its navy panel, with the three
/// animated KPI counters (16+ festivals, 25+ projects, 5000+ trees)
/// centered on screen.
struct ImpactSection: View {

    /// Whether the counters have been triggered.
    let countersArmed: Bool
    /// Reports that the section became visible so the counters can start.
    let onBecameVisible: () -> Void

    @Environment(ContentStore.self) private var content

    /// One column on iPhone, three across on iPad.
    private let columns = [GridItem(.adaptive(minimum: 250, maximum: 400), spacing: 18)]

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 58)

            SceneTitle(
                eyebrow: "Our Impact",
                title: "Roots in community, reach across Lebanon",
                onDark: true
            )

            Text(content.impactIntro)
                .font(YTAFont.body(14, relativeTo: .footnote))
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 620)

            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(content.impactStats) { stat in
                    ImpactStatView(stat: stat, armed: countersArmed)
                }
            }

            Spacer(minLength: 20)
        }
        .padding(.horizontal, YTAMetrics.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            // The verified figures play over the association's own
            // reforestation photograph (#programs, nature.png) — the
            // impact story told on its landscape.
            ZStack {
                KenBurnsImage(imageName: "mission-nature", duration: 22)
                Color.ytaNavy.opacity(0.84)
            }
        }
        .onScrollVisibilityChange(threshold: 0.25) { visible in
            if visible { onBecameVisible() }
        }
    }
}

/// One KPI column: icon, animated number, label and description.
private struct ImpactStatView: View {

    let stat: ImpactStat
    let armed: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: stat.systemImage)
                .font(.system(size: 23, weight: .medium))
                .foregroundStyle(Color.ytaGreenLight)
                .frame(width: 54, height: 54)
                .background(.white.opacity(0.06), in: Circle())
                .overlay(Circle().strokeBorder(.white.opacity(0.12), lineWidth: 1))

            CountUpText(value: stat.value, suffix: stat.suffix, armed: armed)
                .foregroundStyle(.white)

            Text(stat.label)
                .font(YTAFont.semibold(14, relativeTo: .subheadline))
                .foregroundStyle(Color(hex: 0xCBD5E1))

            Text(stat.details)
                .font(YTAFont.body(12, relativeTo: .caption))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .frame(maxWidth: 340)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ImpactSection(countersArmed: true, onBecameVisible: {})
        .frame(height: 700)
        .environment(ContentStore())
}
