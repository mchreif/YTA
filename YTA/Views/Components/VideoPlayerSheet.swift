import SwiftUI
import AVKit

/// Full-screen video player with a close button — the native counterpart of
/// the website's video modals (event promo and festival recaps).
///
/// Playback starts automatically, gains standard transport controls, and the
/// player is torn down on dismissal.
struct VideoPlayerSheet: View {

    /// Title used for accessibility and the navigation context.
    let title: String
    /// Local file URL of the bundled video.
    let url: URL

    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .accessibilityLabel(title)
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.black.opacity(0.55), in: Circle())
            }
            .accessibilityLabel("Close")
            .padding(.top, 8)
            .padding(.trailing, 16)
        }
        .onAppear {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            let player = AVPlayer(url: url)
            self.player = player
            player.play()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}
