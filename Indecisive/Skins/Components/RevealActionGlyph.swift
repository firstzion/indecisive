import SwiftUI

/// The little animated glyph next to the 8-Ball's "SHAKE AGAIN", Gashapon's
/// "One more turn" and Crystal Ball's "Consult again". The Wheel's "SPIN AGAIN"
/// has no glyph in the source design.
struct RevealActionGlyph: View {
    let skin: Skin

    var body: some View {
        // No tint means no glyph — the Wheel's "SPIN AGAIN" stands alone.
        if let tint = skin.reveal.rerollGlyphTint {
            glyph(tint)
                .indIdle(skin.motion.rerollGlyph)
        }
    }

    @ViewBuilder
    private func glyph(_ tint: Color) -> some View {
        Group {
            switch skin.id {
            case .eightBall:
                // Standalone decorative accent — coincides with
                // `palette.flavors[0]`, but this glyph isn't showing "a
                // flavour".
                RoundedRectangle(cornerRadius: 3)
                    .fill(tint)
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(45))
            case .prizeWheel:
                EmptyView()
            case .gashapon:
                // A tiny capsule in the accent color.
                CapsuleBall(top: tint, ink: skin.palette.primaryText, size: 18, seamOpacity: 0.2, glossy: false)
            case .crystalBall:
                // A pink spark that twinkles (`skin.motion.rerollGlyph`).
                Circle()
                    .fill(tint)
                    .frame(width: 16, height: 16)
            }
        }
    }
}
