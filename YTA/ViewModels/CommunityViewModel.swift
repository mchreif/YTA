import Foundation
import Observation

/// Presentation state for the Community screen (alerts + polls).
@MainActor
@Observable
final class CommunityViewModel {

    /// Currently selected segment.
    var segment: CommunityStore.Segment = .alerts

    /// Incremented after each successful vote to fire the confetti burst.
    var confettiTrigger = 0

    /// Casts a vote through the store and celebrates.
    func vote(for option: Poll.Option, in poll: Poll, store: CommunityStore) async {
        guard poll.isOpen, store.votedOptionID(for: poll) == nil else { return }
        await store.vote(for: option, in: poll)
        confettiTrigger += 1
    }

    /// Applies a segment requested from elsewhere in the app
    /// (e.g. the Home screen bell), consuming the request.
    func adoptRequestedSegment(from store: CommunityStore) {
        if let requested = store.requestedSegment {
            segment = requested
            store.requestedSegment = nil
        }
    }
}
