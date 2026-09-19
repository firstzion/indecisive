import SwiftUI

/// The decoration behind the reveal screen: the 8-Ball's pulsing lime glow
/// (PLAN.md §4.4's `ind-glow`: opacity .45↔1 over a 2.6s round trip) or
/// Gashapon's slowly turning sunburst. The Wheel has none, so `RevealView` can
/// include this unconditionally.
struct RevealGlow: View {
    let skin: Skin
    @State private var pulsedUp = false
    @State private var turned = false
    @Environment(\.indReducedMotion) private var reduceMotion

    var body: some View {
        switch skin.id {
        case .eightBall: glow
        case .gashapon: sunburst
        case .prizeWheel: EmptyView()
        }
    }

    private var glow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [skin.palette.accent.opacity(0.22), skin.palette.accent.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: 210
                )
            )
            .frame(width: 420, height: 420)
            // Reduce Motion keeps a static dim glow rather than pulsing
            // — still decorative, just not animated.
            .opacity(pulsedUp ? 1 : 0.45)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                    pulsedUp = true
                }
            }
    }

    /// White rays, 12° wide every 24°, turning once every 26s — the mockup's
    /// `repeating-conic-gradient` on a 520pt disc. Reduce Motion keeps it still.
    private var sunburst: some View {
        // Drawn in an overlay so the 520pt disc, wider than the screen, can't
        // widen the reveal's layout — a fixed-size child in the ZStack does,
        // and the name card and buttons then run edge to edge.
        Color.clear
            .overlay {
                Circle()
                    .fill(AngularGradient(stops: Self.rayStops, center: .center, angle: .degrees(-90)))
                    .frame(width: 520, height: 520)
                    .rotationEffect(.degrees(turned ? 360 : 0))
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 26).repeatForever(autoreverses: false)) {
                    turned = true
                }
            }
    }

    /// 15 rays: each is white at 22% for 12° and clear for the next 12°. Stops
    /// repeat a location to make the hard edges the conic gradient has.
    private static let rayStops: [Gradient.Stop] = (0..<15).flatMap { ray -> [Gradient.Stop] in
        let start = Double(ray) * 24 / 360
        let mid = (Double(ray) * 24 + 12) / 360
        let end = Double(ray + 1) * 24 / 360
        return [
            .init(color: .white.opacity(0.22), location: start),
            .init(color: .white.opacity(0.22), location: mid),
            .init(color: .white.opacity(0), location: mid),
            .init(color: .white.opacity(0), location: end),
        ]
    }
}
