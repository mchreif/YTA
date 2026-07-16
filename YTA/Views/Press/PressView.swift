import SwiftUI

/// The "06 · Press" tab — Arabic press coverage of YTA, rendered
/// right-to-left exactly like the website's news cards, with articles
/// opening in an in-app Safari browser.
///
/// Articles are fed live from `ytalebanon.org/app/news.json` via
/// `NewsStore`, so YTA can publish a new article without an app update —
/// pull to refresh, or it syncs automatically on launch.
struct PressView: View {

    @Environment(ContentStore.self) private var content
    @Environment(NewsStore.self) private var news
    @State private var viewModel = PressViewModel()

    /// Single column on iPhone, two on iPad.
    private let columns = [GridItem(.adaptive(minimum: 330, maximum: 520), spacing: 18)]

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(spacing: 18) {
                SectionHeader(number: "06", title: "Press", subtitle: "News Articles")
                    .padding(.top, 24)

                Text(content.pressIntro)
                    .font(YTAFont.body(15, relativeTo: .subheadline))
                    .foregroundStyle(Color.ytaTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: 620)
                    .padding(.horizontal, YTAMetrics.gutter)

                SyncStatusLabel(
                    isRefreshing: news.isRefreshing,
                    isShowingCachedContent: news.isShowingCachedContent,
                    lastSyncedAt: news.lastSyncedAt
                )

                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(Array(news.articles.enumerated()), id: \.element.id) { index, article in
                        NewsArticleCard(article: article, number: index + 1) {
                            viewModel.read(article)
                        }
                        .ytaReveal()
                    }
                }
                .padding(.horizontal, YTAMetrics.gutter)
                .padding(.bottom, YTAMetrics.sectionSpacing)
            }
        }
        .background(Color.ytaBackground)
        .scrollIndicators(.hidden)
        .refreshable { await news.refresh() }
        .task { await news.loadIfNeeded() }
        .sheet(item: $viewModel.articleInBrowser) { article in
            SafariView(url: article.url)
                .ignoresSafeArea()
        }
    }
}

/// One press card: thumbnail, numbered badge, Arabic headline and summary
/// (laid out right-to-left), and the source + read link footer.
private struct NewsArticleCard: View {

    let article: NewsArticle
    /// 1-based display position — computed from the article's place in
    /// the feed, so YTA never has to manage numbering by hand.
    let number: Int
    let onRead: () -> Void

    var body: some View {
        Button(action: onRead) {
            VStack(alignment: .leading, spacing: 0) {
                thumbnail

                // Arabic headline and summary — right-to-left like the website.
                VStack(alignment: .trailing, spacing: 7) {
                    Text(article.title)
                        .font(YTAFont.bold(18, relativeTo: .headline))
                        .foregroundStyle(Color.ytaTextPrimary)

                    Text(article.summary)
                        .font(YTAFont.body(14, relativeTo: .subheadline))
                        .foregroundStyle(Color.ytaTextSecondary)
                        .lineSpacing(4)
                }
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)
                .padding(.horizontal, 16)
                .padding(.top, 14)

                HStack {
                    Text(article.sourceName)
                        .font(YTAFont.medium(12, relativeTo: .caption))
                        .foregroundStyle(Color.ytaTextSecondary)

                    Spacer()

                    HStack(spacing: 5) {
                        Text("Read article")
                            .font(YTAFont.semibold(13, relativeTo: .caption))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(Color.ytaGreen)
                }
                .padding(16)
            }
            .ytaCardStyle()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the article in the in-app browser")
    }

    /// The article's image: bundled asset (the six launch articles),
    /// a remotely hosted photo (articles YTA publishes later), or — if
    /// neither is supplied — a text-forward branded treatment instead
    /// of a broken-image icon.
    @ViewBuilder
    private var thumbnail: some View {
        Group {
            if let imageName = article.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
            } else if let imageURL = article.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .clipped()
        .overlay(alignment: .topLeading) {
            Text(String(format: "%02d", number))
                .font(YTAFont.bold(11, relativeTo: .caption2))
                .foregroundStyle(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(.black.opacity(0.45), in: Capsule())
                .padding(10)
        }
    }

    /// Branded fallback for articles without any photo.
    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color.ytaSky, Color.ytaBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "newspaper")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Color.ytaGreen.opacity(0.5))
        }
    }
}

#Preview {
    PressView()
        .environment(ContentStore())
        .environment(NewsStore())
}
