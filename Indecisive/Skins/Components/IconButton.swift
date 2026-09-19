import SwiftUI

/// The small round/rounded-square icon buttons used for Home's "+" and the
/// Reveal screen's "✕": a plain circle for Gumball/8-Ball, a bordered
/// rounded square for the Wheel — the same shape language as `CardStyle`
/// and `PrimaryCTAStyle`, just smaller. Added in Phase 3 once screens
/// actually needed it, but it belongs alongside the other shared skin
/// components, not inside a screen file.
struct SkinIconButton: View {
    enum Variant {
        /// Home's "+": always accent-filled.
        case primary
        /// Reveal's "✕": a quieter, low-contrast dismiss control.
        case dismiss
        /// Home's "skins" picker entry point: subtle, same shape language,
        /// no shadow — sits next to "+" without competing with it.
        case secondary
    }

    let skin: Skin
    let glyph: String
    /// A glyph like "+" or "✕" doesn't always read well on its own via
    /// VoiceOver, so every call site names its own label explicitly rather
    /// than relying on the glyph text.
    let accessibilityLabel: String
    var variant: Variant = .primary
    var size: CGFloat = 40
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(glyph)
                .font(skin.type.body(size * 0.4, weight: .bold))
                // Caps the glyph's own Dynamic Type growth so it can't
                // overflow this fixed-size button at accessibility sizes.
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(foreground)
                .frame(width: size, height: size)
                .background(background)
                .clipShape(shape)
                .overlay {
                    if borderWidth > 0 {
                        shape.stroke(skin.palette.primaryText, lineWidth: borderWidth)
                    }
                }
                .indShadow(shadow, cornerRadius: size * 0.32)
                // `size` can be as small as 32pt (Reveal's "✕"), under
                // Apple's 44×44pt minimum tappable target. Pad the *hit
                // area* out to 44×44 without growing the visible shape —
                // `contentShape` extends what counts as "inside the
                // button" to the whole (otherwise-invisible) frame.
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private var shape: AnyShape {
        skin.id == .prizeWheel
            ? AnyShape(RoundedRectangle(cornerRadius: size * 0.32, style: .continuous))
            : AnyShape(Circle())
    }

    private var foreground: Color {
        switch (skin.id, variant) {
        case (_, .primary): return skin.palette.onAccent
        case (.gumball, .dismiss): return .white
        case (.eightBall, .dismiss): return skin.palette.primaryText
        case (.prizeWheel, .dismiss): return skin.palette.primaryText
        case (_, .secondary): return skin.palette.secondaryText
        }
    }

    private var background: Color {
        switch (skin.id, variant) {
        case (_, .primary): return skin.palette.accent
        // Reduced from 0.22 — the white "✕" glyph over that more-opaque
        // tint (effectively #FF6680 on Gumball's reveal background) was
        // only 2.81:1, short of WCAG AA's 3:1. A more transparent pill
        // lets more of the saturated red underneath show through, which
        // is what actually gives the white glyph something to contrast
        // against.
        case (.gumball, .dismiss): return .white.opacity(0.10)
        case (.eightBall, .dismiss): return skin.palette.surface
        case (.prizeWheel, .dismiss): return skin.palette.background
        case (_, .secondary): return skin.palette.surface
        }
    }

    private var borderWidth: CGFloat {
        guard skin.id == .prizeWheel else { return 0 }
        return variant == .primary ? 3 : 2.5
    }

    private var shadow: SkinShadowStyle {
        (skin.id == .prizeWheel && variant == .primary)
            ? .hard(offset: CGSize(width: 3, height: 3), color: skin.palette.primaryText)
            : .none
    }
}
