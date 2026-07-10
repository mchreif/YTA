import SwiftUI

/// The "05 · Media" tab — a snapping coverflow carousel of Instagram
/// post cards plus the follow banner, recreating the website's
/// "Luminous Portal" Instagram feed.
///
/// Instagram embeds are web-only, so each card presents the post's
/// engagement stats on branded artwork and opens the post in the
/// Instagram app or browser — see ARCHITECTURE.md for the documented
/// Instagram Graph API integration point.
struct MediaView: View {

    @Environment(ContentStore.self) private var content
    @Environment(\.openURL) private var openURL
    @State private var viewModel = MediaViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                SectionHeader(number: "05", title: "Media")
                    .padding(.top, 24)

                carousel

                followCard
                    .padding(.horizontal, YTAMetrics.gutter)
                    .padding(.bottom, YTAMetrics.sectionSpacing)
            }
        }
        .background(Color.ytaBackground)
        .scrollIndicators(.hidden)
    }

    // MARK: Carousel

    /// Horizontally snapping post carousel with a coverflow focus effect.
    private var carousel: some View {
        @Bindable var viewModel = viewModel

        return ScrollView(.horizontal) {
            LazyHStack(spacing: 18) {
                ForEach(Array(content.instagramPosts.enumerated()), id: \.element.id) { index, post in
                    InstagramPostCard(post: post, index: index) {
                        viewModel.willOpenPost()
                        openURL(post.url)
                    }
                    .containerRelativeFrame(.horizontal) { length, _ in
                        min(length * 0.72, 320)
                    }
                    .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                        content
                            .scaleEffect(phase.isIdentity ? 1 : 0.88)
                            .opacity(phase.isIdentity ? 1 : 0.55)
                            .rotation3DEffect(
                                .degrees(phase.value * -9),
                                axis: (x: 0, y: 1, z: 0)
                            )
                    }
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, YTAMetrics.gutter)
            .padding(.vertical, 8)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $viewModel.focusedPostID)
        .scrollIndicators(.hidden)
    }

    // MARK: Follow banner

    /// The "Follow our journey · @yta_leb" call-to-action.
    private var followCard: some View {
        Button {
            viewModel.willOpenPost()
            openURL(ExternalLinks.instagram)
        } label: {
            HStack(spacing: 14) {
                Image("logo-yta")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 46, height: 46)
                    .padding(6)
                    .background(.white, in: Circle())
                    .overlay(Circle().strokeBorder(Color.ytaBorder, lineWidth: 1))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Follow our journey")
                        .font(YTAFont.medium(12, relativeTo: .caption))
                        .kerning(1.2)
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(0.75))
                    Text("@\(ExternalLinks.instagramHandle)")
                        .font(YTAFont.bold(22, relativeTo: .title3))
                        .foregroundStyle(.white)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.ytaGold)
            }
            .padding(18)
            .background(
                LinearGradient(
                    colors: [Color.ytaNavy, Color(hex: 0x1E3A5F)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: YTAMetrics.radius, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Follow YTA on Instagram, @\(ExternalLinks.instagramHandle)")
    }
}

/// One branded Instagram post card with the same stats the website shows
/// (likes / comments, and views for reels).
private struct InstagramPostCard: View {

    let post: InstagramPost
    let index: Int
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(spacing: 0) {
                artwork

                stats
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }
            .background(Color.ytaCard)
            .clipShape(RoundedRectangle(cornerRadius: YTAMetrics.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: YTAMetrics.radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.ytaGreen.opacity(0.6), Color.ytaGold.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: .black.opacity(0.10), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("Opens on Instagram")
    }

    /// Branded gradient artwork with the logo watermark, index and
    /// reel badge — the native stand-in for the web embed preview.
    private var artwork: some View {
        ZStack {
            LinearGradient(
                colors: [Color.ytaSky, Color.ytaBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image("logo-yta")
                .resizable()
                .scaledToFit()
                .frame(width: 110)
                .opacity(0.9)

            if post.kind == .reel {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white, Color.ytaGreen)
                    .shadow(radius: 6)
            }
        }
        .frame(height: 220)
        .overlay(alignment: .topLeading) {
            Text(String(format: "%02d", index + 1))
                .font(YTAFont.bold(11, relativeTo: .caption2))
                .foregroundStyle(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(.black.opacity(0.4), in: Capsule())
                .padding(10)
        }
        .overlay(alignment: .topTrailing) {
            if post.kind == .reel {
                Text("Reel")
                    .font(YTAFont.semibold(10, relativeTo: .caption2))
                    .textCase(.uppercase)
                    .kerning(1)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color.ytaGreen, in: Capsule())
                    .padding(10)
            }
        }
        .clipped()
    }

    /// Likes / comments / views row.
    private var stats: some View {
        HStack(spacing: 14) {
            statItem(systemName: "heart", value: post.likes)
            statItem(systemName: "bubble.right", value: post.comments)
            if let views = post.views {
                statItem(systemName: "eye", value: views)
            }
            Spacer()
            Image(systemName: "arrow.up.right.square")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.ytaGreen)
        }
    }

    private func statItem(systemName: String, value: Int) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.ytaTextSecondary)
            Text(InstagramPost.format(count: value))
                .font(YTAFont.semibold(13, relativeTo: .caption))
                .foregroundStyle(Color.ytaTextPrimary)
        }
    }

    private var accessibilitySummary: String {
        var parts = [
            "Instagram \(post.kind == .reel ? "reel" : "post") \(index + 1)",
            "\(post.likes) likes",
            "\(post.comments) comments"
        ]
        if let views = post.views {
            parts.append("\(views) views")
        }
        return parts.joined(separator: ", ")
    }
}

#Preview {
    MediaView()
        .environment(ContentStore())
}
