import SwiftUI

/// The Media tab: a channel switcher between the Instagram feed and the
/// press coverage (website sections 05 and 06 under one roof, freeing a
/// tab slot for Community).
struct MediaHubView: View {

    /// Content channels available in the hub.
    enum Channel: String, CaseIterable, Identifiable {
        case instagram
        case press
        var id: String { rawValue }
    }

    @State private var channel: Channel = .instagram

    var body: some View {
        VStack(spacing: 0) {
            Picker("Channel", selection: $channel) {
                Text("Instagram").tag(Channel.instagram)
                Text("Press").tag(Channel.press)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, YTAMetrics.gutter)
            .padding(.top, 10)
            .padding(.bottom, 2)
            .background(Color.ytaBackground)

            switch channel {
            case .instagram:
                MediaView()
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            case .press:
                PressView()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .background(Color.ytaBackground)
        .animation(.spring(duration: 0.35), value: channel)
    }
}

#Preview {
    MediaHubView()
        .environment(ContentStore())
}
