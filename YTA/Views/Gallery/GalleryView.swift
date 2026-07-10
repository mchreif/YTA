import SwiftUI

/// The "04 · Yammouneh" tab — the photo gallery with a full native
/// lightbox (matched-geometry zoom transition, pinch-to-zoom,
/// drag-to-dismiss, previous/next paging and sharing).
struct GalleryView: View {

    @Environment(ContentStore.self) private var content
    @State private var viewModel = GalleryViewModel()
    @Namespace private var lightboxNamespace

    /// Two columns on iPhone, more on iPad via adaptive sizing.
    private let columns = [GridItem(.adaptive(minimum: 165, maximum: 280), spacing: 14)]

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 26) {
                    SectionHeader(
                        number: "04",
                        title: "Yammouneh",
                        subtitle: "Nature, History, and Living Heritage"
                    )
                    .padding(.top, 24)

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(content.galleryPhotos) { photo in
                            tile(for: photo)
                                .ytaReveal()
                        }
                    }
                    .padding(.horizontal, YTAMetrics.gutter)
                    .padding(.bottom, YTAMetrics.sectionSpacing)
                }
            }
            .background(Color.ytaBackground)
            .scrollIndicators(.hidden)

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
        .animation(.spring(duration: 0.35), value: viewModel.selectedPhoto)
    }

    /// One grid tile with the numbered caption band.
    private func tile(for photo: GalleryPhoto) -> some View {
        Button {
            withAnimation(.spring(duration: 0.35)) {
                viewModel.open(photo)
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Image(photo.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .matchedGeometryEffect(
                        id: photo.id,
                        in: lightboxNamespace,
                        isSource: viewModel.selectedPhoto == nil
                    )

                HStack(spacing: 6) {
                    Text(photo.number)
                        .font(YTAFont.semibold(11, relativeTo: .caption2))
                        .foregroundStyle(Color.ytaGold)
                    Text(photo.title)
                        .font(YTAFont.medium(13, relativeTo: .caption))
                        .foregroundStyle(Color.ytaTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .ytaCardStyle(cornerRadius: YTAMetrics.radiusSmall)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(photo.title), photo \(photo.number)")
        .accessibilityHint("Opens full screen")
    }
}

/// Full-screen photo viewer (the native `yta-lightbox`).
private struct PhotoLightbox: View {

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
            // Reset zoom and drag when paging between photos.
            zoom = 1
            steadyZoom = 1
            dragOffset = .zero
        }
    }

    /// Close, share and paging controls.
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

    /// Backdrop fades as the photo is dragged toward dismissal.
    private var backdropOpacity: Double {
        let distance = abs(dragOffset.height)
        return max(0.35, 1 - distance / 400)
    }

    /// Pinch to zoom between 1x and 4x.
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

    /// Drag down (or up) to dismiss when not zoomed in.
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
