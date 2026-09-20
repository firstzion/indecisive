import SwiftUI

/// The small eyebrow line above the reveal centrepiece ("THE BALL HAS
/// SPOKEN" / "WE HAVE A WINNER" / "CAPSULE CRACKED"). Its face, colour and
/// clearance are the skin's own (`skin.reveal.kicker`): the source design sets
/// it in the body font for the 8-Ball and the display font for the Wheel and
/// Gashapon.
struct RevealKicker: View {
    let skin: Skin

    var body: some View {
        let kicker = skin.reveal.kicker
        Text(skin.copy.revealKicker)
            .font(kicker.font)
            .tracking(2)
            .foregroundStyle(kicker.color)
            .padding(.bottom, kicker.bottomClearance)
    }
}
