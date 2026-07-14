import SwiftUI

/// The Community tab: association alerts (broadcast announcements) and
/// project polls, fed remotely from ytalebanon.org and cached for offline.
struct CommunityView: View {

    @Environment(CommunityStore.self) private var store
    @State private var viewModel = CommunityViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    header

                    Picker("Section", selection: $viewModel.segment) {
                        Text("Alerts").tag(CommunityStore.Segment.alerts)
                        Text("Polls").tag(CommunityStore.Segment.polls)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, YTAMetrics.gutter)

                    syncStatus

                    switch viewModel.segment {
                    case .alerts:
                        AlertsSection()
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                    case .polls:
                        PollsSection(viewModel: viewModel)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }
                .padding(.bottom, YTAMetrics.sectionSpacing)
                .animation(.spring(duration: 0.35), value: viewModel.segment)
            }
            .background(Color.ytaBackground)
            .scrollIndicators(.hidden)
            .refreshable { await store.refresh() }

            ConfettiBurst(trigger: viewModel.confettiTrigger)
        }
        .task {
            await store.loadIfNeeded()
            viewModel.adoptRequestedSegment(from: store)
        }
        .onChange(of: store.requestedSegment) { _, _ in
            viewModel.adoptRequestedSegment(from: store)
        }
    }

    /// Scene banner in the app's cinematic language: the association's
    /// own festival-crowd photograph (site #programs, festivals.png)
    /// under a serif title — community is the festival crowd.
    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            KenBurnsImage(imageName: "mission-festivals", duration: 20)

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.25),
                    .init(color: Color.ytaNavy.opacity(0.9), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 5) {
                Text("Alerts & project votes from YTA")
                    .font(YTAFont.semibold(10, relativeTo: .caption))
                    .kerning(1.8)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.ytaGold)
                Text("Community")
                    .font(YTAFont.display(30, relativeTo: .title))
                    .foregroundStyle(.white)
            }
            .padding(16)
        }
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: YTAMetrics.radius, style: .continuous))
        .padding(.horizontal, YTAMetrics.gutter)
        .padding(.top, 12)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    /// One-line freshness indicator under the segment picker.
    @ViewBuilder
    private var syncStatus: some View {
        if store.isRefreshing {
            Label("Checking for updates…", systemImage: "arrow.triangle.2.circlepath")
                .font(YTAFont.body(12, relativeTo: .caption))
                .foregroundStyle(Color.ytaTextSecondary)
        } else if store.isShowingCachedContent {
            Label("Offline — showing saved content", systemImage: "wifi.slash")
                .font(YTAFont.body(12, relativeTo: .caption))
                .foregroundStyle(Color.ytaTextSecondary)
        } else if let synced = store.lastSyncedAt {
            Label {
                Text("Updated \(synced, format: .relative(presentation: .named))")
            } icon: {
                Image(systemName: "checkmark.circle")
            }
            .font(YTAFont.body(12, relativeTo: .caption))
            .foregroundStyle(Color.ytaTextSecondary)
        }
    }
}

// MARK: - Alerts

/// The broadcast announcements list.
private struct AlertsSection: View {

    @Environment(CommunityStore.self) private var store
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 12) {
            if store.alerts.isEmpty {
                ContentUnavailableView(
                    "No alerts yet",
                    systemImage: "bell",
                    description: Text("Announcements from the association will appear here.")
                )
                .padding(.top, 30)
            } else {
                ForEach(store.alerts) { alert in
                    AlertCard(alert: alert, isUnread: store.isUnread(alert)) { url in
                        HapticsManager.tap()
                        openURL(url)
                    }
                    .ytaReveal()
                }
            }
        }
        .padding(.horizontal, YTAMetrics.gutter)
        .onAppear { store.markAlertsRead() }
    }
}

/// One announcement card, tinted by severity.
private struct AlertCard: View {

    let alert: CommunityAlert
    let isUnread: Bool
    let onOpenLink: (URL) -> Void

    private var tint: Color {
        switch alert.severity {
        case .info:   .ytaGreen
        case .event:  .ytaGold
        case .urgent: Color(hex: 0xDC2626)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: alert.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 38, height: 38)
                    .background(tint.opacity(0.14), in: Circle())
                    .symbolEffect(.bounce, value: isUnread)

                VStack(alignment: .leading, spacing: 2) {
                    Text(alert.title)
                        .font(YTAFont.bold(16, relativeTo: .headline))
                        .foregroundStyle(Color.ytaTextPrimary)
                    Text(alert.date, format: .relative(presentation: .named))
                        .font(YTAFont.body(12, relativeTo: .caption))
                        .foregroundStyle(Color.ytaTextSecondary)
                }

                Spacer()

                if isUnread {
                    Circle()
                        .fill(tint)
                        .frame(width: 9, height: 9)
                        .accessibilityLabel("Unread")
                }
            }

            Text(alert.message)
                .font(YTAFont.body(14, relativeTo: .subheadline))
                .foregroundStyle(Color.ytaTextSecondary)
                .lineSpacing(3)

            if let url = alert.linkURL {
                Button {
                    onOpenLink(url)
                } label: {
                    HStack(spacing: 5) {
                        Text("Learn more")
                            .font(YTAFont.semibold(13, relativeTo: .caption))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(tint)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ytaCardStyle()
        .overlay(alignment: .leading) {
            UnevenRoundedRectangle(
                topLeadingRadius: YTAMetrics.radius,
                bottomLeadingRadius: YTAMetrics.radius
            )
            .fill(tint)
            .frame(width: 4)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Polls

/// The project polls list.
private struct PollsSection: View {

    @Environment(CommunityStore.self) private var store
    let viewModel: CommunityViewModel

    var body: some View {
        VStack(spacing: 16) {
            if store.polls.isEmpty {
                ContentUnavailableView(
                    "No polls yet",
                    systemImage: "chart.bar.xaxis",
                    description: Text("When YTA opens a project vote, it will appear here.")
                )
                .padding(.top, 30)
            } else {
                ForEach(store.polls) { poll in
                    PollCard(
                        poll: poll,
                        votedOptionID: store.votedOptionID(for: poll),
                        onVote: { option in
                            Task { await viewModel.vote(for: option, in: poll, store: store) }
                        }
                    )
                    .ytaReveal()
                }

                Text("One vote per device · results shared at community meetings")
                    .font(YTAFont.body(11, relativeTo: .caption2))
                    .foregroundStyle(Color.ytaTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, YTAMetrics.gutter)
    }
}

/// One poll: question, status, and either vote buttons or animated results.
private struct PollCard: View {

    let poll: Poll
    /// The option chosen on this device, `nil` until the user votes.
    let votedOptionID: String?
    let onVote: (Poll.Option) -> Void

    @State private var barsVisible = false

    /// Results replace buttons once the user voted or the poll closed.
    private var showsResults: Bool {
        votedOptionID != nil || !poll.isOpen
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(poll.question)
                        .font(YTAFont.bold(18, relativeTo: .headline))
                        .foregroundStyle(Color.ytaTextPrimary)
                    Text(poll.details)
                        .font(YTAFont.body(13, relativeTo: .footnote))
                        .foregroundStyle(Color.ytaTextSecondary)
                        .lineSpacing(3)
                }
                Spacer()
                statusChip
            }

            VStack(spacing: 8) {
                ForEach(poll.options) { option in
                    if showsResults {
                        resultRow(for: option)
                    } else {
                        voteButton(for: option)
                    }
                }
            }

            HStack {
                Label("\(poll.totalVotes) votes", systemImage: "person.2.fill")
                if let closesAt = poll.closesAt, poll.isOpen {
                    Spacer()
                    Label {
                        Text("Closes \(closesAt, format: .relative(presentation: .named))")
                    } icon: {
                        Image(systemName: "clock")
                    }
                }
            }
            .font(YTAFont.medium(12, relativeTo: .caption))
            .foregroundStyle(Color.ytaTextSecondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ytaCardStyle()
        .onAppear {
            withAnimation(.spring(duration: 0.9, bounce: 0.2).delay(0.15)) {
                barsVisible = true
            }
        }
        .accessibilityElement(children: .contain)
    }

    /// "Open" (green) or "Closed" (neutral) capsule.
    private var statusChip: some View {
        Text(poll.isOpen ? "Open" : "Closed")
            .font(YTAFont.semibold(11, relativeTo: .caption2))
            .textCase(.uppercase)
            .kerning(1)
            .foregroundStyle(poll.isOpen ? Color.ytaGreen : Color.ytaTextSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                (poll.isOpen ? Color.ytaGreen : Color.ytaTextSecondary).opacity(0.12),
                in: Capsule()
            )
    }

    /// Tappable option before voting.
    private func voteButton(for option: Poll.Option) -> some View {
        Button {
            onVote(option)
        } label: {
            HStack {
                Image(systemName: "circle")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.ytaGreen)
                Text(option.title)
                    .font(YTAFont.medium(15, relativeTo: .subheadline))
                    .foregroundStyle(Color.ytaTextPrimary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.ytaGreen.opacity(0.06), in: RoundedRectangle(cornerRadius: YTAMetrics.radiusSmall, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: YTAMetrics.radiusSmall, style: .continuous)
                    .strokeBorder(Color.ytaGreen.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Casts your vote")
    }

    /// Animated result bar after voting / closing.
    private func resultRow(for option: Poll.Option) -> some View {
        let share = poll.share(of: option)
        let isChosen = option.id == votedOptionID
        let isWinner = !poll.isOpen && option.id == poll.winner?.id
        let barColor: Color = isWinner ? .ytaGold : (isChosen ? .ytaGreen : .ytaSky)

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                if isChosen {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.ytaGreen)
                }
                if isWinner {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.ytaGold)
                }
                Text(option.title)
                    .font(YTAFont.medium(14, relativeTo: .subheadline))
                    .foregroundStyle(Color.ytaTextPrimary)
                Spacer()
                Text("\(Int((share * 100).rounded()))%")
                    .font(YTAFont.bold(14, relativeTo: .subheadline))
                    .monospacedDigit()
                    .foregroundStyle(Color.ytaTextPrimary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.ytaBorder.opacity(0.5))
                    Capsule()
                        .fill(barColor)
                        .frame(width: max(barsVisible ? proxy.size.width * share : 0, share > 0 ? 6 : 0))
                }
            }
            .frame(height: 10)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(option.title), \(Int((share * 100).rounded())) percent, \(option.votes) votes")
    }
}

#Preview {
    CommunityView()
        .environment(CommunityStore())
}
