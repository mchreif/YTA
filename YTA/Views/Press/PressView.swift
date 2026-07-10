import SwiftUI

/// The "06 · Press" tab — Arabic press coverage of YTA, rendered
/// right-to-left exactly like the website's news cards, with articles
/// opening in an in-app Safari browser.
struct PressView: View {

    @Environment(ContentStore.self) private var content
    @State private var viewModel = PressViewModel()

    /// Single column on iPhone, two on iPad.
    private let columns = [GridItem(.adaptive(minimum: 330, maximum: 520), spacing: 18)]

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(spacing: 26) {
                SectionHeader(number: "06", title: "Press", subtitle: "News Articles")
                    .padding(.top, 24)

                Text(content.pressIntro)
                    .font(YTAFont.body(15, relativeTo: .subheadline))
                    .foregroundStyle(Color.ytaTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: 620)
                    .padding(.horizontal, YTAMetrics.gutter)

                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(content.newsArticles) { article in
                        NewsArticleCard(article: article) {
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
    let onRead: () -> Void

    var body: some View {
        Button(action: onRead) {
            VStack(alignment: .leading, spacing: 0) {
                Image(article.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .overlay(alignment: .topLeading) {
                        Text(article.number)
                            .font(YTAFont.bold(11, relativeTo: .caption2))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.45), in: Capsule())
                            .padding(10)
                    }

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
}

#Preview {
    PressView()
        .environment(ContentStore())
}
