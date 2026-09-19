import SwiftUI

/// The pulsing lime glow behind the 8-Ball's reveal screen (PLAN.md §4.4's
/// `ind-glow`: opacity .45↔1 over a 2.6s round trip). Every other skin
/// renders nothing, so `RevealView` can include this unconditionally.
struct RevealGlow: View {
    let skin: Skin
    @State private var pulsedUp = false
    @Environment(\.indReducedMotion) private var reduceMotion

    var body: some View {
        if skin.id == .eightBall {
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
    }
}
