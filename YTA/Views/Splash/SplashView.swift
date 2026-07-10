import SwiftUI

/// Animated launch intro: the NGO logo rises over a living mesh-gradient
/// backdrop with rippling rings (the native evolution of the website's
/// preloader), then hands off to the main app after ~3.5 seconds.
struct SplashView: View {

    /// Called when the intro has finished.
    let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var logoVisible = false
    @State private var taglineVisible = false
    @State private var rippling = false

    var body: some View {
        ZStack {
            AnimatedMeshBackground()

            VStack(spacing: 22) {
                ZStack {
                    if !reduceMotion {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .stroke(Color.white.opacity(0.35), lineWidth: 1.2)
                                .frame(width: 150, height: 150)
                                .scaleEffect(rippling ? 2.4 : 0.95)
                                .opacity(rippling ? 0 : 0.9)
                                .animation(
                                    .easeOut(duration: 2.4)
                                        .repeatForever(autoreverses: false)
                                        .delay(Double(index) * 0.8),
                                    value: rippling
                                )
                        }
                    }

                    Image("logo-ngo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 148, height: 148)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(.white.opacity(0.85), lineWidth: 3))
                        .shadow(color: .black.opacity(0.35), radius: 24, y: 10)
                        .scaleEffect(logoVisible ? 1 : 0.55)
                        .opacity(logoVisible ? 1 : 0)
                }

                VStack(spacing: 10) {
                    Text("Yammouneh Tourism Association")
                        .font(YTAFont.semibold(17, relativeTo: .headline))
                        .kerning(1.2)
                        .textCase(.uppercase)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Springs, ruins & living heritage")
                        .font(YTAFont.displayRegular(19, relativeTo: .title3))
                        .foregroundStyle(Color.ytaGold)
                }
                .padding(.horizontal, 32)
                .opacity(taglineVisible ? 1 : 0)
                .offset(y: taglineVisible ? 0 : 14)

                ProgressView()
                    .tint(.white.opacity(0.7))
                    .padding(.top, 8)
                    .opacity(taglineVisible ? 1 : 0)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Yammouneh Tourism Association")
        .task {
            withAnimation(.spring(duration: 0.8, bounce: 0.4)) {
                logoVisible = true
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.5)) {
                taglineVisible = true
            }
            rippling = true
            try? await Task.sleep(for: .seconds(reduceMotion ? 2.0 : 3.5))
            onFinished()
        }
    }
}

/// Slowly drifting brand-colored mesh gradient (iOS 18 `MeshGradient`).
/// Static under Reduce Motion.
struct AnimatedMeshBackground: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                mesh(at: 0)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                    mesh(at: context.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .ignoresSafeArea()
    }

    /// Builds the mesh for a moment in time; the two interior control
    /// points orbit slowly, making the colors breathe.
    private func mesh(at t: TimeInterval) -> some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5],
                [
                    Float(0.5 + 0.16 * sin(t * 0.6)),
                    Float(0.5 + 0.16 * cos(t * 0.8))
                ],
                [1, 0.5],
                [0, 1],
                [
                    Float(0.5 + 0.14 * cos(t * 0.5)),
                    1
                ],
                [1, 1]
            ],
            colors: [
                Color(hex: 0x0B1220), Color(hex: 0x0F172A), Color(hex: 0x14532D),
                Color(hex: 0x0F172A), Color(hex: 0x166534), Color(hex: 0x0B1220),
                Color(hex: 0x14532D), Color(hex: 0x0F172A), Color(hex: 0x052E16)
            ]
        )
    }
}

#Preview {
    SplashView(onFinished: {})
}
