import SwiftUI

/// The board full page — intro text, a snapping horizontal rail of
/// member cards, and the Plan-Your-Visit banner that closes the
/// Home journey.
struct BoardSection: View {

    /// Switches to the Connect tab (the approved Home flow ends on a
    /// "Plan your visit" entry point).
    let onPlanVisit: () -> Void

    @Environment(ContentStore.self) private var content

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 58)

            SceneTitle(
                eyebrow: "Board Members",
                title: "Leadership & Governance"
            )
            .padding(.horizontal, YTAMetrics.gutter)

            Text(content.boardIntro)
                .font(YTAFont.body(14, relativeTo: .footnote))
                .foregroundStyle(Color.ytaTextSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 620)
                .padding(.horizontal, YTAMetrics.gutter)

            ScrollView(.horizontal) {
                LazyHStack(spacing: 16) {
                    ForEach(content.boardMembers) { member in
                        BoardMemberCard(member: member)
                            .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1 : 0.94)
                                    .opacity(phase.isIdentity ? 1 : 0.7)
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, YTAMetrics.gutter, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)

            planVisitBanner
                .padding(.horizontal, YTAMetrics.gutter)

            Spacer(minLength: 20)
        }
    }

    /// The Home journey's closing action, using the site's own visit copy.
    private var planVisitBanner: some View {
        Button {
            HapticsManager.impact()
            onPlanVisit()
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Plan Your Visit")
                        .font(YTAFont.displayRegular(19, relativeTo: .title3))
                        .foregroundStyle(.white)
                    Text("Routes, guided tours, festival dates — 24h typical response")
                        .font(YTAFont.body(12, relativeTo: .caption))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.ytaGold)
            }
            .padding(18)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0x14532D), Color.ytaNavy],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: YTAMetrics.radius, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Plan your visit")
        .accessibilityHint("Opens the Connect tab")
    }
}

/// A single board member card with portrait, number, role and name.
private struct BoardMemberCard: View {

    let member: BoardMember

    var body: some View {
        VStack(spacing: 0) {
            Image(member.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 200, height: 210)
                .clipped()
                .overlay(alignment: .topLeading) {
                    Text(member.number)
                        .font(YTAFont.bold(11, relativeTo: .caption2))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.45), in: Capsule())
                        .padding(8)
                }

            VStack(spacing: 3) {
                Text(member.role)
                    .font(YTAFont.semibold(11, relativeTo: .caption2))
                    .kerning(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.ytaGreen)

                Text(member.name)
                    .font(YTAFont.bold(16, relativeTo: .headline))
                    .foregroundStyle(Color.ytaTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .frame(width: 200)
        }
        .ytaCardStyle(cornerRadius: YTAMetrics.radius)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(member.name), \(member.role)")
    }
}

#Preview {
    BoardSection(onPlanVisit: {})
        .frame(height: 700)
        .background(Color.ytaBackground)
        .environment(ContentStore())
}
