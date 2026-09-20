import SwiftUI

/// The small colored icon on a Home-screen list row: a dark ball with a
/// flavor-tinted diamond (8-Ball), a conic prize wheel (Prize Wheel) or a
/// two-tone capsule (Gashapon). `flavorIndex` selects the list's own color from
/// `skin.palette.flavors`; `itemCount` only matters for the Wheel, which
/// draws one wedge per item (capped for legibility).
struct ListBadge: View {
    let skin: Skin
    let flavorIndex: Int
    let itemCount: Int
    var size: CGFloat = 46

    private var flavor: Color {
        let flavors = skin.palette.flavors
        guard !flavors.isEmpty else { return skin.palette.accent }
        return flavors[flavorIndex % flavors.count]
    }

    var body: some View {
        Group {
            switch skin.id {
            case .eightBall:
                // The 8-ball's own shell black — same paint as
                // `revealBackground` (see also `HeroBadge`, `PrimaryCTAGlyph`,
                // `RevealCentrepiece`).
                Circle()
                    .fill(skin.palette.revealBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: size * 0.07, style: .continuous)
                            .fill(flavor)
                            .frame(width: size * 0.5, height: size * 0.5)
                            .rotationEffect(.degrees(45))
                    }

            case .prizeWheel:
                WheelFill(wedgeCount: wheelWedgeCount(forItemCount: itemCount), colors: skin.palette.flavors)
                    .overlay {
                        Circle().strokeBorder(skin.palette.primaryText, lineWidth: 3)
                    }

            case .gashapon:
                CapsuleBall(top: flavor, ink: skin.palette.primaryText, size: size)
            }
        }
        .frame(width: size, height: size)
    }
}
