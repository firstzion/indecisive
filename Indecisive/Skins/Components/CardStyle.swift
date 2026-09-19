import SwiftUI

/// The list-row / grouped-card treatment: a thin neon border with no shadow
/// for the 8-Ball, and a thick ink border with a hard offset "sticker"
/// shadow for the Wheel.
struct CardStyle: ViewModifier {
    let skin: Skin

    func body(content: Content) -> some View {
        content
            .background(skin.palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: skin.shape.cardRadius, style: .continuous))
            .overlay {
                if let border = skin.palette.surfaceBorder, skin.shape.cardBorderWidth > 0 {
                    RoundedRectangle(cornerRadius: skin.shape.cardRadius, style: .continuous)
                        .strokeBorder(border, lineWidth: skin.shape.cardBorderWidth)
                }
            }
            .indShadow(skin.shape.cardShadow, cornerRadius: skin.shape.cardRadius)
    }
}

extension View {
    func indCard(_ skin: Skin) -> some View {
        modifier(CardStyle(skin: skin))
    }
}
