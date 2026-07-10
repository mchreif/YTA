import SwiftUI
import AVFoundation
import AVKit

/// Muted, looping, aspect-fill video layer — the native counterpart of the
/// website's autoplaying hero `<video>`.
///
/// Uses `AVPlayerLooper` over an `AVQueuePlayer` for gapless looping and
/// configures the audio session as ambient so the silent hero never
/// interrupts the user's music.
struct LoopingVideoView: UIViewRepresentable {

    /// Local file URL of the video to loop.
    let url: URL

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.configure(with: url)
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        // The hero video never changes at runtime; nothing to update.
    }

    static func dismantleUIView(_ uiView: PlayerContainerView, coordinator: ()) {
        uiView.teardown()
    }

    /// UIView whose backing layer is an `AVPlayerLayer`.
    final class PlayerContainerView: UIView {

        private var player: AVQueuePlayer?
        private var looper: AVPlayerLooper?
        private var foregroundObserver: NSObjectProtocol?

        override static var layerClass: AnyClass { AVPlayerLayer.self }

        private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

        /// Builds the looping player pipeline for the given file.
        func configure(with url: URL) {
            try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .moviePlayback)

            let item = AVPlayerItem(url: url)
            let queuePlayer = AVQueuePlayer()
            queuePlayer.isMuted = true
            queuePlayer.preventsDisplaySleepDuringVideoPlayback = false

            looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
            player = queuePlayer

            playerLayer.player = queuePlayer
            playerLayer.videoGravity = .resizeAspectFill
            queuePlayer.play()

            // Resume playback when the app returns to the foreground —
            // the system pauses video layers on backgrounding.
            foregroundObserver = NotificationCenter.default.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.player?.play()
            }
        }

        /// Stops playback and releases observers when SwiftUI discards the view.
        func teardown() {
            if let foregroundObserver {
                NotificationCenter.default.removeObserver(foregroundObserver)
            }
            foregroundObserver = nil
            player?.pause()
            looper = nil
            player = nil
            playerLayer.player = nil
        }
    }
}
