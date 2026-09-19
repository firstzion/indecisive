import SwiftUI

/// How a skin draws depth. Gumball uses a soft, barely-there drop shadow;
/// the Wheel uses a hard-edged "sticker" shadow (an offset ink-colored
/// duplicate, no blur); the 8-Ball skips shadows for a colored glow instead.
enum SkinShadowStyle: Sendable {
    case soft(radius: CGFloat, x: CGFloat, y: CGFloat, color: Color, opacity: Double)
    case hard(offset: CGSize, color: Color)
    case glow(color: Color, radius: CGFloat, opacity: Double)
    case none
}

extension View {
    /// Applies a `SkinShadowStyle`. `.hard` needs `cornerRadius` to draw its
    /// offset duplicate with the same shape as the content it sits behind.
    @ViewBuilder
    func indShadow(_ style: SkinShadowStyle, cornerRadius: CGFloat) -> some View {
        switch style {
        case let .soft(radius, x, y, color, opacity):
            self.shadow(color: color.opacity(opacity), radius: radius, x: x, y: y)
        case let .glow(color, radius, opacity):
            self.shadow(color: color.opacity(opacity), radius: radius, x: 0, y: 0)
        case let .hard(offset, color):
            self.background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(color)
                    .offset(offset)
            )
        case .none:
            self
        }
    }
}

/// Corner radii, border widths and the shadow language for cards, dashed
/// rows and the primary CTA. See `CardStyle` and `PrimaryCTAStyle`.
struct SkinShape: Sendable {
    let cardRadius: CGFloat
    let cardBorderWidth: CGFloat
    let cardShadow: SkinShadowStyle

    let dashedBorderWidth: CGFloat
    let dashedCornerRadius: CGFloat

    let ctaHeight: CGFloat
    /// Large enough to read as a pill on Gumball/8-Ball; a plain rounded
    /// rect (~20) on the Wheel.
    let ctaCornerRadius: CGFloat
    let ctaBorderWidth: CGFloat
    let ctaShadow: SkinShadowStyle
}
