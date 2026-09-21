import SwiftUI

/// The decoration behind the reveal screen: the 8-Ball's pulsing lime glow,
/// Gashapon's slowly turning sunburst or Crystal Ball's pulsing pink haze. The
/// Wheel has none, so `RevealView` can include this unconditionally. What is
/// drawn is per skin; how it moves is the skin's own `motion.revealBackdrop`.
struct RevealGlow: View {
    let skin: Skin

    var body: some View {
        // A skin with no `backdropTint` draws nothing — that's how the Wheel
        // opts out, rather than by being named here.
        if let tint = skin.reveal.backdropTint {
            switch skin.id {
            case .eightBall: glow(tint)
            case .gashapon: sunburst(tint)
            case .crystalBall: haze(tint)
            case .prizeWheel: EmptyView()
            }
        }
    }

    private func glow(_ tint: Color) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [tint.opacity(0.22), tint.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: 210
                )
            )
            .frame(width: 420, height: 420)
            // Reduce Motion keeps a static dim glow rather than pulsing
            // — still decorative, just not animated.
            .indIdle(skin.motion.revealBackdrop)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    /// A 460pt disc of pink, densest at the middle and gone by 62 % of the way to the corner —
    /// the mockup's `radial-gradient(circle, rgba(255,139,209,.3), transparent 62%)`.
    /// Reduce Motion keeps it still, at its dim end.
    private func haze(_ tint: Color) -> some View {
        // Drawn in an overlay for the same reason as the sunburst below: 460pt is wider than the
        // screen, and a fixed-size child in the ZStack would widen the reveal's whole layout.
        Color.clear
            .overlay {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [tint.opacity(0.3), tint.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            // 62 % of the distance from the centre to the corner of a 460pt box.
                            endRadius: 0.62 * 230 * 2.0.squareRoot()
                        )
                    )
                    .frame(width: 460, height: 460)
                    .indIdle(skin.motion.revealBackdrop)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    /// White rays, 12° wide every 24° — the mockup's `repeating-conic-gradient`
    /// on a 520pt disc. Reduce Motion keeps it still.
    private func sunburst(_ tint: Color) -> some View {
        // Drawn in an overlay so the 520pt disc, wider than the screen, can't
        // widen the reveal's layout — a fixed-size child in the ZStack does,
        // and the name card and buttons then run edge to edge.
        Color.clear
            .overlay {
                Circle()
                    .fill(AngularGradient(stops: Self.rayStops(tint), center: .center, angle: .degrees(-90)))
                    .frame(width: 520, height: 520)
                    .indIdle(skin.motion.revealBackdrop)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    /// 15 rays: each is white at 22% for 12° and clear for the next 12°. Stops
    /// repeat a location to make the hard edges the conic gradient has.
    private static func rayStops(_ tint: Color) -> [Gradient.Stop] {
        (0..<15).flatMap { ray -> [Gradient.Stop] in
            let start = Double(ray) * 24 / 360
            let mid = (Double(ray) * 24 + 12) / 360
            let end = Double(ray + 1) * 24 / 360
            return [
                .init(color: tint.opacity(0.22), location: start),
                .init(color: tint.opacity(0.22), location: mid),
                .init(color: tint.opacity(0), location: mid),
                .init(color: tint.opacity(0), location: end),
            ]
        }
    }
}
