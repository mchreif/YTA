import SwiftUI

/// One-line freshness indicator for a screen backed by a live JSON feed
/// (Community's alerts/polls, Press's articles): shows whether a refresh
/// is in flight, whether the content shown is an offline cache, or how
/// long ago the last successful sync completed.
struct SyncStatusLabel: View {

    let isRefreshing: Bool
    let isShowingCachedContent: Bool
    let lastSyncedAt: Date?

    var body: some View {
        if isRefreshing {
            Label("Checking for updates…", systemImage: "arrow.triangle.2.circlepath")
                .font(YTAFont.body(12, relativeTo: .caption))
                .foregroundStyle(Color.ytaTextSecondary)
        } else if isShowingCachedContent {
            Label("Offline — showing saved content", systemImage: "wifi.slash")
                .font(YTAFont.body(12, relativeTo: .caption))
                .foregroundStyle(Color.ytaTextSecondary)
        } else if let lastSyncedAt {
            Label {
                Text("Updated \(lastSyncedAt, format: .relative(presentation: .named))")
            } icon: {
                Image(systemName: "checkmark.circle")
            }
            .font(YTAFont.body(12, relativeTo: .caption))
            .foregroundStyle(Color.ytaTextSecondary)
        }
    }
}
