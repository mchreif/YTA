import SwiftUI

/// The Explore tab — "Cinema of the Valley": a full-bleed seasonal scene
/// header, the gold route-line journey through the six official
/// attraction scenes, and a filmstrip that opens the zoom lightbox.
///
/// Every photograph and caption comes from ytalebanon.org (#yammouneh);
/// seasons group what the photos themselves depict. The journey is
/// thematic, not GPS — stated in the UI until YTA supplies coordinates.
struct GalleryView: View {

    @Environment(ContentStore.self) private var content
    @State private var viewModel = GalleryViewModel()
    @State private var season: ValleySeason = .summer
    /// Scroll offset feeding the hero's parallax (0 at rest).
    @State private var heroOffset: CGFloat = 0
    @Namespace private var zoomNamespace
    @Namespace private var lightboxNamespace

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 0) {
                        // The approved hero artwork (title embedded in the
                        // image) dissolving into the journey ground; the
                        // season selector hangs into the transition zone.
                        YammounehHeroTransition(
                            imageName: "yammouneh-header",
                            height: 450,
                            fadeColor: .ytaJourneyBackground,
                            scrollOffset: heroOffset
                        ) {
                            EmptyView()
                        }
                        .overlay(alignment: .bottom) {
                            seasonSwitcher
                                .offset(y: 22)
                        }
                        .zIndex(1)

                        VStack(spacing: 0) {
                            journey
                            filmstrip
                        }
                        .background(alignment: .top) {
                            JourneyAtmosphere()
                        }
                    }
                }
                .background(Color.ytaJourneyBackground)
                .ignoresSafeArea(edges: .top)
                .scrollIndicators(.hidden)
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y + geometry.contentInsets.top
                } action: { _, offset in
                    heroOffset = offset
                }
                .toolbarVisibility(.hidden, for: .navigationBar)

                if let photo = viewModel.selectedPhoto {
                    PhotoLightbox(
                        photo: photo,
                        photos: content.galleryPhotos,
                        namespace: lightboxNamespace,
                        onStep: { viewModel.step($0, in: content.galleryPhotos) },
                        onClose: {
                            withAnimation(.spring(duration: 0.35)) {
                                viewModel.close()
                            }
                        }
                    )
                    .zIndex(1)
                }
            }
            .navigationDestination(for: GalleryPhoto.self) { photo in
                AttractionDetailView(photo: photo, zoomNamespace: zoomNamespace)
            }
        }
        .animation(.spring(duration: 0.35), value: viewModel.selectedPhoto)
    }

    // MARK: Season selector

    /// Refined floating capsule: light translucency, thin border, strong
    /// selected state — hanging in the hero's transition zone. The HStack
    /// mirrors automatically under RTL.
    private var seasonSwitcher: some View {
        HStack(spacing: 4) {
            ForEach(ValleySeason.allCases) { s in
                Button {
                    HapticsManager.selection()
                    withAnimation(.spring(duration: 0.35)) {
                        season = s
                    }
                } label: {
                    Text(s.title)
                        .font(YTAFont.semibold(12, relativeTo: .caption))
                        .foregroundStyle(season == s ? .white : .white.opacity(0.72))
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(
                            season == s ? Color.ytaGreen : Color.clear,
                            in: Capsule()
                        )
                }
                .accessibilityAddTraits(season == s ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.10), in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.22), lineWidth: 1))
        .shadow(color: .black.opacity(0.35), radius: 12, y: 5)
    }

    // MARK: Journey

    /// The route-line journey: six scenes threaded by the gold path.
    private var journey: some View {
        VStack(spacing: 0) {
            ForEach(Array(content.galleryPhotos.enumerated()), id: \.element.id) { index, photo in
                if index > 0 {
                    RouteConnector(swayLeading: index.isMultiple(of: 2))
                }
                NavigationLink(value: photo) {
                    JourneyStop(
                        photo: photo,
                        imageOnLeading: index.isMultiple(of: 2),
                        dimmed: photo.season != season
                    )
                    .matchedTransitionSource(id: photo.id, in: zoomNamespace)
                }
                .buttonStyle(.plain)
                .ytaReveal()
            }

            Text("A thematic journey — scenes, not GPS points.")
                .font(YTAFont.body(11, relativeTo: .caption2))
                .foregroundStyle(.white.opacity(0.45))
                .padding(.top, 18)
        }
        .padding(.horizontal, YTAMetrics.gutter)
        .padding(.top, 52)
    }

    // MARK: Filmstrip

    /// Quick full-screen viewing of all six frames (the classic lightbox).
    private var filmstrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("The valley in six frames")
                .font(YTAFont.displayRegular(20, relativeTo: .title3))
                .foregroundStyle(.white)
                .padding(.horizontal, YTAMetrics.gutter)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(content.galleryPhotos) { photo in
                        Button {
                            withAnimation(.spring(duration: 0.35)) {
                                viewModel.open(photo)
                            }
                        } label: {
                            Image(photo.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 108, height: 78)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .matchedGeometryEffect(
                                    id: photo.id,
                                    in: lightboxNamespace,
                                    isSource: viewModel.selectedPhoto == nil
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(photo.title), open full screen")
                    }
                }
                .padding(.horizontal, YTAMetrics.gutter)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.vertical, 30)
    }
}

/// One stop on the journey: photo, gold ordinal, serif caption and season.
private struct JourneyStop: View {

    let photo: GalleryPhoto
    let imageOnLeading: Bool
    /// Stops outside the selected season recede slightly (never hidden).
    let dimmed: Bool

    var body: some View {
        HStack(spacing: 14) {
            if imageOnLeading { thumbnail }

            VStack(alignment: imageOnLeading ? .leading : .trailing, spacing: 4) {
                Text(photo.number)
                    .font(YTAFont.semibold(11, relativeTo: .caption2))
                    .foregroundStyle(Color.ytaGold)
                Text(photo.title)
                    .font(YTAFont.displayRegular(20, relativeTo: .title3))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(imageOnLeading ? .leading : .trailing)
                Text(photo.season.title)
                    .font(YTAFont.medium(11, relativeTo: .caption2))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .frame(maxWidth: .infinity, alignment: imageOnLeading ? .leading : .trailing)

            if !imageOnLeading { thumbnail }
        }
        .opacity(dimmed ? 0.55 : 1)
        .animation(.easeInOut(duration: 0.4), value: dimmed)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(photo.title), scene \(photo.number)")
        .accessibilityHint("Opens the scene")
    }

    private var thumbnail: some View {
        Image(photo.imageName)
            .resizable()
            .scaledToFill()
            .frame(width: 128, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.ytaGold.opacity(dimmed ? 0 : 0.45), lineWidth: 1)
            )
    }
}

/// Full-screen photo viewer (the native `yta-lightbox`), shared by the
/// Explore filmstrip and the attraction detail screens.
struct PhotoLightbox: View {

    let photo: GalleryPhoto
    let photos: [GalleryPhoto]
    let namespace: Namespace.ID
    /// Steps to the previous (-1) or next (+1) photo.
    let onStep: (Int) -> Void
    let onClose: () -> Void

    @State private var zoom: CGFloat = 1
    @State private var steadyZoom: CGFloat = 1
    @State private var dragOffset: CGSize = .zero

    private var isFirst: Bool { photos.first == photo }
    private var isLast: Bool { photos.last == photo }

    var body: some View {
        ZStack {
            Color.black
                .opacity(backdropOpacity)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer()

                Image(photo.imageName)
                    .resizable()
                    .scaledToFit()
                    .matchedGeometryEffect(id: photo.id, in: namespace, isSource: true)
                    .clipShape(RoundedRectangle(cornerRadius: YTAMetrics.radiusSmall, style: .continuous))
                    .scaleEffect(zoom)
                    .offset(dragOffset)
                    .gesture(magnification)
                    .simultaneousGesture(dismissDrag)
                    .accessibilityLabel(photo.title)

                HStack(spacing: 6) {
                    Text(photo.number)
                        .font(YTAFont.semibold(13, relativeTo: .caption))
                        .foregroundStyle(Color.ytaGold)
                    Text(photo.title)
                        .font(YTAFont.displayRegular(20, relativeTo: .title3))
                        .foregroundStyle(.white)
                }
                .opacity(backdropOpacity)

                Spacer()
            }
            .padding(.horizontal, 24)

            controls
        }
        .onChange(of: photo) {
            zoom = 1
            steadyZoom = 1
            dragOffset = .zero
        }
    }

    private var controls: some View {
        VStack {
            HStack {
                ShareLink(
                    item: Image(photo.imageName),
                    preview: SharePreview(photo.title, image: Image(photo.imageName))
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(.white.opacity(0.12), in: Circle())
                }
                .accessibilityLabel("Share photo")

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(.white.opacity(0.12), in: Circle())
                }
                .accessibilityLabel("Close")
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Spacer()

            HStack {
                pagingButton(systemName: "chevron.left", disabled: isFirst) { onStep(-1) }
                Spacer()
                pagingButton(systemName: "chevron.right", disabled: isLast) { onStep(1) }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .opacity(backdropOpacity)
    }

    private func pagingButton(systemName: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .padding(14)
                .background(.white.opacity(0.12), in: Circle())
        }
        .disabled(disabled)
        .opacity(disabled ? 0.3 : 1)
    }

    private var backdropOpacity: Double {
        let distance = abs(dragOffset.height)
        return max(0.35, 1 - distance / 400)
    }

    private var magnification: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                zoom = min(max(steadyZoom * value.magnification, 1), 4)
            }
            .onEnded { _ in
                steadyZoom = zoom
                if zoom <= 1.05 {
                    withAnimation(.spring(duration: 0.3)) {
                        zoom = 1
                        steadyZoom = 1
                    }
                }
            }
    }

    private var dismissDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                guard zoom <= 1.05 else { return }
                dragOffset = value.translation
            }
            .onEnded { value in
                guard zoom <= 1.05 else { return }
                if abs(value.translation.height) > 130 {
                    onClose()
                } else {
                    withAnimation(.spring(duration: 0.3)) {
                        dragOffset = .zero
                    }
                }
            }
    }
}

#Preview {
    GalleryView()
        .environment(ContentStore())
}
