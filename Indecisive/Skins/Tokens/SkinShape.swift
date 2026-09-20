import SwiftUI

/// How a skin draws depth. The Wheel uses a hard-edged "sticker" shadow (an
/// offset ink-colored duplicate, no blur); the 8-Ball skips shadows for a
/// colored glow instead. `.soft` is a plain drop shadow, and `.none` draws
/// nothing.
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

/// A hard-edged band hugging the *inside* of a shape's edge — CSS's
/// `inset x y 0 color`. Drawn by `InsetShadow`.
struct SkinInsetShadow: Sendable {
    let color: Color
    let x: CGFloat
    let y: CGFloat
}

/// The outline of the small icon buttons (Home's "+", the reveal's "✕").
enum SkinIconShape: Sendable {
    case circle
    /// A rounded square whose corner radius is `cornerFraction` of its side.
    case roundedSquare(cornerFraction: CGFloat)
}

/// How the small icon buttons are drawn: Home's "+" and "🎨", the reveal's "✕".
/// See `SkinIconButton`.
struct SkinIconButtonStyle: Sendable {
    let shape: SkinIconShape
    /// Outline round the accent-filled "+" (0 draws none).
    let primaryBorderWidth: CGFloat
    /// Outline round the quieter buttons — the skins picker's and the reveal's "✕".
    let quietBorderWidth: CGFloat
    /// Depth under the "+"; the quieter buttons never cast one.
    let primaryShadow: SkinShadowStyle
}

/// Corner radii, border widths and the shadow language for cards, dashed
/// rows, the primary CTA and the small icon buttons. See `CardStyle`,
/// `PrimaryCTAStyle` and `SkinIconButton`.
struct SkinShape: Sendable {
    let cardRadius: CGFloat
    let cardBorderWidth: CGFloat
    let cardShadow: SkinShadowStyle

    let dashedBorderWidth: CGFloat
    let dashedCornerRadius: CGFloat

    let ctaHeight: CGFloat
    /// Large enough to read as a pill on the 8-Ball; a plain rounded
    /// rect (~20) on the Wheel.
    let ctaCornerRadius: CGFloat
    let ctaBorderWidth: CGFloat
    let ctaShadow: SkinShadowStyle
    /// A darker lip along the CTA's bottom edge (Gashapon's mockup has
    /// `inset 0 -4px 0 rgba(0,0,0,.12)`); `nil` draws none.
    let ctaInsetShadow: SkinInsetShadow?

    let iconButton: SkinIconButtonStyle
}
