import SwiftUI

/// Brand-colored confetti burst rendered with `Canvas`, fired whenever
/// `trigger` changes — celebrates a recorded poll vote.
///
/// The particle field is deterministic per trigger (seeded generator), so
/// each Canvas frame just evaluates positions analytically: no per-particle
/// state, and the timeline pauses itself when the burst ends.
struct ConfettiBurst: View {

    /// Increment to fire a new burst.
    let trigger: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var burstStart: Date?

    private static let colors: [Color] = [.ytaGreen, .ytaGold, .ytaSky, .ytaGreenLight, .white]
    private static let particleCount = 48
    private static let lifetime: TimeInterval = 1.5

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: burstStart == nil)) { context in
            Canvas { graphics, size in
                guard let start = burstStart else { return }
                let t = context.date.timeIntervalSince(start)
                guard t >= 0, t < Self.lifetime else { return }

                var random = SeededGenerator(seed: UInt64(truncatingIfNeeded: trigger &+ 7))
                let origin = CGPoint(x: size.width / 2, y: size.height * 0.35)

                for index in 0..<Self.particleCount {
                    let angle = Double.random(in: -Double.pi...0, using: &random)
                    let speed = Double.random(in: 190...420, using: &random)
                    let spin = Double.random(in: -6...6, using: &random)
                    let sizeSide = CGFloat.random(in: 5...9, using: &random)
                    let color = Self.colors[index % Self.colors.count]

                    let x = origin.x + CGFloat(cos(angle) * speed * t)
                    let y = origin.y + CGFloat(sin(angle) * speed * t + 380 * t * t)
                    let fade = 1 - (t / Self.lifetime)

                    var contextCopy = graphics
                    contextCopy.translateBy(x: x, y: y)
                    contextCopy.rotate(by: .radians(spin * t))
                    contextCopy.opacity = fade
                    contextCopy.fill(
                        Path(CGRect(x: -sizeSide / 2, y: -sizeSide / 2, width: sizeSide, height: sizeSide * 0.62)),
                        with: .color(color)
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) { _, _ in
            guard !reduceMotion else { return }
            burstStart = .now
            Task {
                try? await Task.sleep(for: .seconds(Self.lifetime + 0.1))
                burstStart = nil
            }
        }
    }
}

/// Small deterministic random generator so every Canvas frame of one burst
/// sees identical particle parameters.
struct SeededGenerator: RandomNumberGenerator {

    private var state: UInt64

    init(seed: UInt64) {
        state = seed &* 0x9E3779B97F4A7C15 &+ 1
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
