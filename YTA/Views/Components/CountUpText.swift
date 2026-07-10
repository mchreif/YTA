import SwiftUI

/// Animated counter that counts from zero to `value` once `armed`
/// becomes true — the native counterpart of the website's
/// `data-yta-count` intersection-observer counters.
///
/// The count is stepped by a short task with an ease-out curve and the
/// digits roll with `contentTransition(.numericText)`. The task finishes
/// after the animation, so nothing keeps running afterwards.
struct CountUpText: View {

    /// Final value to reach.
    let value: Int
    /// Suffix appended after the number (the site uses "+").
    let suffix: String
    /// Starts the animation when it flips to `true`.
    let armed: Bool
    /// Animation length in seconds.
    var duration: Double = 1.8

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var current = 0

    var body: some View {
        Text("\(current)\(suffix)")
            .font(YTAFont.bold(34, relativeTo: .title))
            .monospacedDigit()
            .contentTransition(.numericText(value: Double(current)))
            .task(id: armed) {
                guard armed, current < value else { return }
                guard !reduceMotion else {
                    current = value
                    return
                }
                await countUp()
            }
            .accessibilityLabel("\(value)\(suffix)")
    }

    /// Steps the counter along an ease-out cubic curve, then stops.
    private func countUp() async {
        let steps = 45
        for step in 1...steps {
            let interval = duration / Double(steps)
            try? await Task.sleep(for: .milliseconds(Int(interval * 1000)))
            guard !Task.isCancelled else { return }
            let progress = Double(step) / Double(steps)
            let eased = 1 - pow(1 - progress, 3)
            withAnimation(.linear(duration: interval)) {
                current = Int(Double(value) * eased)
            }
        }
        current = value
    }
}

#Preview {
    CountUpText(value: 5000, suffix: "+", armed: true)
        .foregroundStyle(Color.ytaGreen)
        .padding()
}
