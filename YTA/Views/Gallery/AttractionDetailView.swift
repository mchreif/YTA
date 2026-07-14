import SwiftUI

/// A full attraction scene: cinematic push-in hero, the official story,
/// contact actions, and related scenes — reached from the Explore journey
/// with an iOS 18 zoom transition.
///
/// Content provenance: photo + caption from ytalebanon.org #yammouneh;
/// story text is the linked official mission program's description,
/// quoted unmodified (#programs); directions use the site's verified
/// village coordinate; guide requests go to the official email.
struct AttractionDetailView: View {

    let photo: GalleryPhoto
    let zoomNamespace: Namespace.ID

    @Environment(ContentStore.self) private var content
    @Environment(\.openURL) private var openURL
    @Namespace private var lightboxNamespace
    @State private var lightboxPhoto: GalleryPhoto?

    /// The official program narrating this scene.
    private var storyProgram: Program? {
        content.program(withID: photo.storyProgramID)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                story
                relatedRail
            }
        }
        .background(Color.ytaNavy)
        .ignoresSafeArea(edges: .top)
        .scrollIndicators(.hidden)
        .navigationTransition(.zoom(sourceID: photo.id, in: zoomNamespace))
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .fullScreenCover(item: $lightboxPhoto) { current in
            PhotoLightbox(
                photo: current,
                photos: content.galleryPhotos,
                namespace: lightboxNamespace,
                onStep: { direction in stepLightbox(direction, from: current) },
                onClose: { lightboxPhoto = nil }
            )
        }
    }

    // MARK: Hero

    /// The scene itself: slow push-in, scrim, ordinal + serif caption.
    /// Tapping opens the full-screen lightbox.
    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            KenBurnsImage(imageName: photo.imageName, duration: 14)

            SceneScrim()

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(photo.number)
                        .font(YTAFont.semibold(11, relativeTo: .caption2))
                        .foregroundStyle(Color.ytaGold)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(Capsule().strokeBorder(Color.ytaGold.opacity(0.5), lineWidth: 1))
                    Text(photo.season.title)
                        .font(YTAFont.semibold(10, relativeTo: .caption2))
                        .kerning(1.6)
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(0.75))
                }

                Text(photo.title)
                    .font(YTAFont.display(34, relativeTo: .largeTitle))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, YTAMetrics.gutter)
            .padding(.bottom, 22)
        }
        .frame(height: 430)
        .clipped()
        .overlay(alignment: .topTrailing) {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(10)
                .background(.black.opacity(0.4), in: Circle())
                .padding(.top, 54)
                .padding(.trailing, 16)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            HapticsManager.tap()
            lightboxPhoto = photo
        }
        .accessibilityLabel("\(photo.title) photograph")
        .accessibilityHint("Opens full screen with zoom")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: Story

    /// The official narrative and the contact actions.
    @ViewBuilder
    private var story: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let program = storyProgram {
                Text(program.title)
                    .font(YTAFont.semibold(11, relativeTo: .caption))
                    .kerning(1.6)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.ytaGreen)

                Text(program.details)
                    .font(YTAFont.body(15, relativeTo: .subheadline))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineSpacing(5)
            }

            HStack(spacing: 10) {
                Button {
                    HapticsManager.tap()
                    openURL(ExternalLinks.appleMapsURL(
                        latitude: content.contact.coordinate.latitude,
                        longitude: content.contact.coordinate.longitude,
                        label: "Yammouneh"
                    ))
                } label: {
                    Text("Directions")
                }
                .buttonStyle(YTASolidButtonStyle())

                Button {
                    HapticsManager.tap()
                    openURL(guideMailURL)
                } label: {
                    Text("Ask a guide")
                }
                .buttonStyle(YTAGlassButtonStyle())

                ShareLink(
                    item: Image(photo.imageName),
                    preview: SharePreview(photo.title, image: Image(photo.imageName))
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(13)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().strokeBorder(.white.opacity(0.4), lineWidth: 1))
                }
                .accessibilityLabel("Share this scene")
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, YTAMetrics.gutter)
        .padding(.vertical, 24)
    }

    /// Mail link to the association's official address, pre-filled with
    /// the site's "Visit Yammouneh" subject plus this scene's name.
    private var guideMailURL: URL {
        let subject = "Visit Yammouneh – \(photo.title)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Visit%20Yammouneh"
        return URL(string: "mailto:\(content.contact.email)?subject=\(subject)")
            ?? content.contact.emailURL
    }

    // MARK: Related

    /// Other official scenes from the same story or season.
    @ViewBuilder
    private var relatedRail: some View {
        let related = content.relatedPhotos(to: photo)
        if !related.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Related scenes")
                    .font(YTAFont.displayRegular(20, relativeTo: .title3))
                    .foregroundStyle(.white)
                    .padding(.horizontal, YTAMetrics.gutter)

                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(related) { other in
                            NavigationLink(value: other) {
                                ZStack(alignment: .bottomLeading) {
                                    Image(other.imageName)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 168, height: 110)
                                        .clipped()
                                    LinearGradient(
                                        colors: [.clear, .black.opacity(0.65)],
                                        startPoint: .center,
                                        endPoint: .bottom
                                    )
                                    Text(other.title)
                                        .font(YTAFont.medium(12, relativeTo: .caption))
                                        .foregroundStyle(.white)
                                        .padding(8)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Open \(other.title)")
                        }
                    }
                    .padding(.horizontal, YTAMetrics.gutter)
                }
                .scrollIndicators(.hidden)
            }
            .padding(.bottom, 40)
        }
    }

    /// Pages the lightbox through the full official gallery.
    private func stepLightbox(_ direction: Int, from current: GalleryPhoto) {
        guard let index = content.galleryPhotos.firstIndex(of: current) else { return }
        let next = index + direction
        guard content.galleryPhotos.indices.contains(next) else { return }
        HapticsManager.selection()
        lightboxPhoto = content.galleryPhotos[next]
    }
}

#Preview {
    @Previewable @Namespace var namespace
    NavigationStack {
        AttractionDetailView(
            photo: GalleryPhoto(id: "yam2", number: "02", title: "Roman Ruins", imageName: "gallery-yam2", season: .summer, storyProgramID: "p5"),
            zoomNamespace: namespace
        )
    }
    .environment(ContentStore())
}
