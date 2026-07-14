import SwiftUI
import AVFoundation
import CoreImage
import CoreVideo

/// The hero welcome avatar — the native version of the website's
/// poster-to-video reveal: a cut-out of Ali Chreif stands over the hero;
/// tapping him expands the frame and plays his welcome message, then
/// collapses back to the poster when it ends (or is tapped again).
///
/// Provenance: poster `welcome_avatar.png` and video `menhem-ios.mp4`
/// are the site's own hero assets; the accessibility label is the site's
/// aria-label. The clip ships with a black backdrop — exactly like the
/// website's canvas keyer, a Core Image color-cube turns those black
/// pixels transparent so only the speaker floats over the hero.
struct WelcomeAvatar: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPlaying = false

    var body: some View {
        Group {
            if isPlaying, let url = VideoLibrary.welcomeMessage {
                WelcomeVideoPlayer(url: url) {
                    stop()
                }
                .frame(width: 190, height: 252)
                .contentShape(Rectangle())
                .onTapGesture { stop() }
                .transition(.scale(scale: 0.45, anchor: .bottomTrailing).combined(with: .opacity))
                .accessibilityLabel("Welcome message playing")
                .accessibilityHint("Tap to close")
                .accessibilityAddTraits(.isButton)
            } else {
                Button {
                    HapticsManager.impact()
                    withAnimation(reduceMotion ? nil : .spring(duration: 0.6, bounce: 0.25)) {
                        isPlaying = true
                    }
                } label: {
                    Image("welcome-avatar")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 112)
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.ytaNavy)
                                .padding(7)
                                .background(Color.ytaGold, in: Circle())
                                .offset(x: 2, y: 2)
                        }
                        .shadow(color: .black.opacity(0.45), radius: 10, y: 4)
                }
                .transition(.scale(scale: 0.7, anchor: .bottomTrailing).combined(with: .opacity))
                .accessibilityLabel("Play welcome message from Ali Chreif")
            }
        }
    }

    private func stop() {
        withAnimation(reduceMotion ? nil : .spring(duration: 0.5)) {
            isPlaying = false
        }
    }
}

/// Inline player for the welcome message: plays once with sound, reports
/// completion, and applies a black-key video composition so the clip's
/// backdrop is genuinely transparent over the hero.
private struct WelcomeVideoPlayer: UIViewRepresentable {

    let url: URL
    let onFinished: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinished: onFinished)
    }

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.configure(with: url, coordinator: context.coordinator)
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        // The clip never changes while presented.
    }

    static func dismantleUIView(_ uiView: PlayerView, coordinator: Coordinator) {
        uiView.teardown()
    }

    final class Coordinator {
        let onFinished: () -> Void
        var endObserver: NSObjectProtocol?

        init(onFinished: @escaping () -> Void) {
            self.onFinished = onFinished
        }
    }

    final class PlayerView: UIView {

        private var player: AVPlayer?
        private weak var coordinator: Coordinator?

        override static var layerClass: AnyClass { AVPlayerLayer.self }
        private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

        func configure(with url: URL, coordinator: Coordinator) {
            self.coordinator = coordinator

            // The welcome message is spoken — switch to the playback
            // category and activate the session so the voice is audible
            // even though the muted hero loop registered as ambient.
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback, mode: .moviePlayback)
            try? session.setActive(true)

            let asset = AVURLAsset(url: url)
            let item = AVPlayerItem(asset: asset)
            let player = AVPlayer(playerItem: item)
            player.isMuted = false
            player.volume = 1
            self.player = player

            playerLayer.player = player
            playerLayer.videoGravity = .resizeAspect
            // Request an alpha-capable pixel format so keyed frames
            // composite transparently over the hero.
            playerLayer.pixelBufferAttributes = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]

            coordinator.endObserver = NotificationCenter.default.addObserver(
                forName: AVPlayerItem.didPlayToEndTimeNotification,
                object: item,
                queue: .main
            ) { [weak coordinator] _ in
                coordinator?.onFinished()
            }

            // Build the black-key composition off the main thread, then
            // start playback. If composition creation fails for any
            // reason, the clip still plays (unkeyed) rather than staying
            // silent and blank.
            let cubeData = Self.blackKeyCubeData
            Task { [weak self] in
                let composition = try? await AVMutableVideoComposition.videoComposition(
                    with: asset,
                    applyingCIFiltersWithHandler: { request in
                        guard
                            let filter = CIFilter(
                                name: "CIColorCubeWithColorSpace",
                                parameters: [
                                    "inputCubeDimension": Self.cubeDimension,
                                    "inputCubeData": cubeData,
                                    "inputColorSpace": CGColorSpaceCreateDeviceRGB(),
                                    kCIInputImageKey: request.sourceImage
                                ]
                            ),
                            let output = filter.outputImage
                        else {
                            request.finish(with: request.sourceImage, context: nil)
                            return
                        }
                        request.finish(with: output, context: nil)
                    }
                )
                await MainActor.run { [weak self] in
                    if let composition {
                        self?.player?.currentItem?.videoComposition = composition
                    }
                    self?.player?.play()
                }
            }
        }

        func teardown() {
            if let observer = coordinator?.endObserver {
                NotificationCenter.default.removeObserver(observer)
                coordinator?.endObserver = nil
            }
            player?.pause()
            player = nil
            playerLayer.player = nil
        }

        // MARK: Black-key color cube

        static let cubeDimension = 32

        /// Color cube mapping near-black pixels to transparent with a soft
        /// rolloff — the same keying the website performs per-pixel on its
        /// canvas. Colors are premultiplied by the computed alpha.
        static let blackKeyCubeData: Data = {
            let size = cubeDimension
            let lowCut: Float = 0.10   // fully transparent below
            let highCut: Float = 0.24  // fully opaque above
            var cube = [Float]()
            cube.reserveCapacity(size * size * size * 4)
            for b in 0..<size {
                for g in 0..<size {
                    for r in 0..<size {
                        let rf = Float(r) / Float(size - 1)
                        let gf = Float(g) / Float(size - 1)
                        let bf = Float(b) / Float(size - 1)
                        let brightness = max(rf, max(gf, bf))
                        let t = min(max((brightness - lowCut) / (highCut - lowCut), 0), 1)
                        let alpha = t * t * (3 - 2 * t) // smoothstep
                        cube.append(rf * alpha)
                        cube.append(gf * alpha)
                        cube.append(bf * alpha)
                        cube.append(alpha)
                    }
                }
            }
            return cube.withUnsafeBufferPointer { Data(buffer: $0) }
        }()
    }
}

#Preview {
    ZStack {
        Color.ytaNavy.ignoresSafeArea()
        WelcomeAvatar()
    }
}
