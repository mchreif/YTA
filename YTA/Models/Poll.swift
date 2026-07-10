import Foundation

/// A community vote about an association project.
///
/// Polls are published by the YTA admin as JSON at
/// `https://ytalebanon.org/app/polls.json`; adding a poll to that file makes
/// it appear for every user — no app update required. Votes are submitted
/// to `vote.php` (included in `Server/`) and tallied server-side; the app
/// also counts the user's own vote locally so results feel instant.
struct Poll: Identifiable, Codable, Hashable, Sendable {

    /// One selectable answer.
    struct Option: Identifiable, Codable, Hashable, Sendable {
        let id: String
        let title: String
        /// Current vote count (server tally; locally incremented after voting).
        var votes: Int
    }

    let id: String
    /// The question, e.g. "Which project should YTA prioritize next?"
    let question: String
    /// Context shown under the question.
    let details: String
    /// Closing date — `nil` keeps the poll open indefinitely.
    let closesAt: Date?
    var options: [Option]

    /// Whether votes are still accepted.
    var isOpen: Bool {
        guard let closesAt else { return true }
        return closesAt > .now
    }

    var totalVotes: Int {
        options.reduce(0) { $0 + $1.votes }
    }

    /// Share of the vote for an option, 0…1.
    func share(of option: Option) -> Double {
        guard totalVotes > 0 else { return 0 }
        return Double(option.votes) / Double(totalVotes)
    }

    /// The leading option — highlighted in gold once a poll closes.
    var winner: Option? {
        options.max { $0.votes < $1.votes }
    }
}
