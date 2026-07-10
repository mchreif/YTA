import SwiftUI

/// The "01 · Mission" full page — the six program cards presented as a
/// snapping horizontal pager with a position counter, so the section
/// occupies exactly one screen like the website's full-viewport section.
struct MissionSection: View {

    /// Plays a festival recap video full screen.
    let onPlayFestival: (FestivalVideo) -> Void

    @Environment(ContentStore.self) private var content
    @State private var focusedProgramID: String?

    /// Index of the card currently snapped into view.
    private var focusedIndex: Int {
        guard
            let focusedProgramID,
            let index = content.programs.firstIndex(where: { $0.id == focusedProgramID })
        else { return 0 }
        return index
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 58)

            SectionHeader(number: "01", title: "Mission")
                .padding(.horizontal, YTAMetrics.gutter)

            carousel

            pagerControls

            Spacer(minLength: 16)
        }
    }

    /// Horizontally snapping program cards.
    private var carousel: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 16) {
                ForEach(content.programs) { program in
                    ProgramCard(program: program, onPlayFestival: onPlayFestival)
                        .containerRelativeFrame(.horizontal) { length, _ in
                            min(length * 0.8, 400)
                        }
                        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                            content
                                .scaleEffect(phase.isIdentity ? 1 : 0.93)
                                .opacity(phase.isIdentity ? 1 : 0.65)
                        }
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, YTAMetrics.gutter, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $focusedProgramID)
        .scrollIndicators(.hidden)
    }

    /// Previous / next arrows around the "02 / 06" position counter.
    private var pagerControls: some View {
        HStack(spacing: 18) {
            arrowButton(systemName: "chevron.left", disabled: focusedIndex == 0) {
                step(-1)
            }

            Text(verbatim: String(format: "%02d / %02d", focusedIndex + 1, content.programs.count))
                .font(YTAFont.semibold(14, relativeTo: .callout))
                .monospacedDigit()
                .foregroundStyle(Color.ytaTextSecondary)
                .contentTransition(.numericText())

            arrowButton(systemName: "chevron.right", disabled: focusedIndex == content.programs.count - 1) {
                step(1)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func arrowButton(systemName: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(disabled ? Color.ytaTextSecondary.opacity(0.35) : Color.ytaGreen)
                .frame(width: 34, height: 34)
                .background(Color.ytaGreen.opacity(disabled ? 0.04 : 0.1), in: Circle())
        }
        .disabled(disabled)
        .accessibilityLabel(systemName.contains("left") ? "Previous program" : "Next program")
    }

    /// Snaps the carousel one card forward or back.
    private func step(_ direction: Int) {
        let target = focusedIndex + direction
        guard content.programs.indices.contains(target) else { return }
        HapticsManager.selection()
        withAnimation(.spring(duration: 0.45)) {
            focusedProgramID = content.programs[target].id
        }
    }
}

/// A single mission program card.
private struct ProgramCard: View {

    let program: Program
    let onPlayFestival: (FestivalVideo) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            media

            VStack(alignment: .leading, spacing: 8) {
                Text(program.title)
                    .font(YTAFont.bold(19, relativeTo: .title3))
                    .foregroundStyle(Color.ytaTextPrimary)
                    .lineLimit(2)

                Text(program.details)
                    .font(YTAFont.body(14, relativeTo: .subheadline))
                    .foregroundStyle(Color.ytaTextSecondary)
                    .lineSpacing(3)
                    .lineLimit(6)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .ytaCardStyle()
        .accessibilityElement(children: .combine)
    }

    /// Card image with the index badge and, for the festivals program,
    /// the year buttons overlaid at the bottom (website: `.year-badges`).
    private var media: some View {
        Image(program.imageName)
            .resizable()
            .scaledToFill()
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.4)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .overlay(alignment: .topLeading) {
                Text(program.number)
                    .font(YTAFont.bold(12, relativeTo: .caption))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.45), in: Capsule())
                    .padding(10)
            }
            .overlay(alignment: .bottom) {
                if !program.festivalVideos.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(program.festivalVideos) { video in
                            Button {
                                onPlayFestival(video)
                            } label: {
                                Label(String(video.year), systemImage: "play.fill")
                                    .font(YTAFont.bold(12, relativeTo: .caption))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 11)
                                    .padding(.vertical, 7)
                                    .background(Color.ytaGreen.opacity(0.95), in: Capsule())
                            }
                            .accessibilityLabel("Play \(video.year) festival video")
                        }
                    }
                    .padding(.bottom, 12)
                }
            }
    }
}

#Preview {
    MissionSection(onPlayFestival: { _ in })
        .frame(height: 700)
        .background(Color.ytaBackground)
        .environment(ContentStore())
}
