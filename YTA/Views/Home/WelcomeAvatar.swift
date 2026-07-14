import SwiftUI
import AVFoundation

/// The hero welcome avatar — the native version of the website's
/// poster-to-video reveal: a cut-out of Ali Chreif stands over the hero;
/// tapping him expands the frame and plays his welcome message, then
/// collapses back to the poster when it ends (or is tapped again).
///
/// Provenance: poster `welcome_avatar.png` and video `menhem-ios.mp4`
/// are the site's own hero assets; the accessibility label is the site's
/// aria-label. The video ships with a black background — the same
/// screen-blend keying trick the website uses makes it melt into the
/// dark hero.
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

/// Inline player for the welcome video: plays once with sound, reports
/// completion, and screen-blends its layer so the clip's black backdrop
/// disappears against the dark hero.
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
            // The welcome message is spoken — use the playback category
            // so it is audible; the muted hero loop is unaffected.
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)

            let item = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: item)
            self.player = player
            playerLayer.player = player
            playerLayer.videoGravity = .resizeAspect
            // Same keying idea as the website: screen-blend removes the
            // clip's black background over the dark hero. If the filter
            // is unavailable the video simply renders in its frame.
            layer.compositingFilter = "screenBlendMode"

            coordinator.endObserver = NotificationCenter.default.addObserver(
                forName: AVPlayerItem.didPlayToEndTimeNotification,
                object: item,
                queue: .main
            ) { [weak coordinator] _ in
                coordinator?.onFinished()
            }
            player.play()
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
    }
}

#Preview {
    ZStack {
        Color.ytaNavy.ignoresSafeArea()
        WelcomeAvatar()
    }
}
