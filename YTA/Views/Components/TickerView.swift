import SwiftUI

/// Infinite horizontal marquee of "Discover" chips, replicating the
/// website's `yta-ticker` band under the hero.
///
/// Two copies of the chip row scroll continuously; when Reduce Motion is on,
/// the chips are shown in a static scrollable row instead.
struct TickerView: View {

    /// Items to display, each rendered as a numbered chip.
    let items: [String]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rowWidth: CGFloat = 0
    @State private var offset: CGFloat = 0

    /// Points per second of marquee travel.
    private let speed: CGFloat = 40

    var body: some View {
        HStack(spacing: 12) {
            badge

            if reduceMotion {
                ScrollView(.horizontal, showsIndicators: false) {
                    chipRow.padding(.trailing, 16)
                }
            } else {
                marquee
            }
        }
        .padding(.vertical, 12)
        .padding(.leading, 16)
        .background(Color.ytaNavy)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Discover: \(items.joined(separator: ", "))"))
    }

    /// The pulsing "Discover" label at the leading edge.
    private var badge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.ytaGold)
                .frame(width: 7, height: 7)
            Text("Discover")
                .font(YTAFont.semibold(12, relativeTo: .caption))
                .kerning(1.5)
                .textCase(.uppercase)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.white.opacity(0.08), in: Capsule())
    }

    /// The endlessly scrolling chip band.
    private var marquee: some View {
        GeometryReader { proxy in
            HStack(spacing: 24) {
                chipRow
                chipRow
            }
            .onGeometryChange(for: CGFloat.self) { geometry in
                geometry.size.width
            } action: { width in
                // Two identical rows joined by one 24pt gap:
                // total = 2 × row + 24, so one row is (total − 24) / 2.
                rowWidth = (width - 24) / 2
            }
            .offset(x: -offset)
            .frame(width: proxy.size.width, alignment: .leading)
            .clipped()
            .onChange(of: rowWidth) { _, width in
                guard width > 0 else { return }
                offset = 0
                withAnimation(.linear(duration: width / speed).repeatForever(autoreverses: false)) {
                    offset = width + 24
                }
            }
        }
        .frame(height: 34)
    }

    /// One copy of the chip sequence.
    private var chipRow: some View {
        HStack(spacing: 24) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(spacing: 7) {
                    Text(String(format: "%02d", index + 1))
                        .font(YTAFont.semibold(11, relativeTo: .caption2))
                        .foregroundStyle(Color.ytaGold)
                    Text(item)
                        .font(YTAFont.medium(13, relativeTo: .caption))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .lineLimit(1)
                .fixedSize()
            }
        }
    }
}

#Preview {
    TickerView(items: [
        "84 Natural Springs", "Roman Heritage", "Yammouneh Lake",
        "Music Festivals", "Eco-Tourism", "Sustainable Lebanon"
    ])
}
