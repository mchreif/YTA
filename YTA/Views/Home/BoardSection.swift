import SwiftUI

/// The "03 · Board Members" full page — intro text and a snapping
/// horizontal rail of large member cards, centered on screen.
struct BoardSection: View {

    @Environment(ContentStore.self) private var content

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 58)

            SectionHeader(
                number: "03",
                title: "Board Members",
                subtitle: "Leadership & Governance"
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

            Spacer(minLength: 20)
        }
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
    BoardSection()
        .frame(height: 700)
        .background(Color.ytaBackground)
        .environment(ContentStore())
}
