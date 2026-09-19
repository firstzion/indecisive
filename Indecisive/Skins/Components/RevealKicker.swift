import SwiftUI

/// The small eyebrow line above the reveal centrepiece ("THE BALL HAS
/// SPOKEN" / "WE HAVE A WINNER" / "CAPSULE CRACKED"). Font family genuinely
/// differs per skin in the source design (body font for the 8-Ball, display
/// font for the Wheel and Gashapon), so this switches rather than using one
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
        case .eightBall: return skin.type.body(14, weight: .extrabold)
        case .prizeWheel: return skin.type.display(19)
        case .gashapon: return skin.type.display(15)
        }
    }

    // Internal (not `private`) so `ContrastTests` can check it directly
    // against `revealBackground` instead of duplicating this switch.
    var kickerColor: Color {
        switch skin.id {
        case .eightBall: return skin.palette.accent
        case .prizeWheel: return skin.palette.primaryText
        case .gashapon: return GashaponPaint.revealInk
        }
    }
}
