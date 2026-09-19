import SwiftUI

/// The small eyebrow line above the reveal centrepiece ("And the winner
/// is…" / "THE BALL HAS SPOKEN" / "WE HAVE A WINNER"). Font family genuinely
/// differs per skin in the source design (body font for Gumball/8-Ball,
/// display font for the Wheel), so this switches rather than using one
/// shared token.
struct RevealKicker: View {
    let skin: Skin

    var body: some View {
        Text(skin.copy.revealKicker)
            .font(kickerFont)
            .tracking(2)
            .foregroundStyle(kickerColor)
            // The Wheel's pointer overlaps the centrepiece below it (see
            // `RevealCentrepiece`'s `Triangle`) — this bit of extra
            // clearance keeps the two from colliding.
            .padding(.bottom, skin.id == .prizeWheel ? 8 : 0)
    }

    private var kickerFont: Font {
        switch skin.id {
        case .gumball, .eightBall: return skin.type.body(14, weight: .extrabold)
        case .prizeWheel: return skin.type.display(19)
        }
    }

    // Internal (not `private`) so `ContrastTests` can check it directly
    // against `revealBackground` instead of duplicating this switch.
    var kickerColor: Color {
        switch skin.id {
        case .gumball:
            // Lightened from the design's #FFD9E1 (2.70:1 on Gumball's
            // reveal background #FF3B5C, fails WCAG AA's 3:1 for large
            // text — this is 14pt extrabold, which qualifies as "large").
            return Color(hex: 0xFFF0F3)
        case .eightBall: return skin.palette.accent
        case .prizeWheel: return skin.palette.primaryText
        }
    }
}
