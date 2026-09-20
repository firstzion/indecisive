import SwiftUI

/// The small round/rounded-square icon buttons used for Home's "+" and the
/// Reveal screen's "✕": a plain circle for the 8-Ball and Gashapon, a bordered
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
        switch skin.id {
        case .prizeWheel: return AnyShape(RoundedRectangle(cornerRadius: size * 0.32, style: .continuous))
        case .eightBall, .gashapon: return AnyShape(Circle())
        }
    }

    private var foreground: Color {
        switch (skin.id, variant) {
        case (_, .primary): return skin.palette.onAccent
        case (.eightBall, .dismiss): return skin.palette.primaryText
        case (.prizeWheel, .dismiss): return skin.palette.primaryText
        case (.gashapon, .dismiss): return GashaponPaint.revealInk
        case (_, .secondary): return skin.palette.secondaryText
        }
    }

    private var background: Color {
        switch (skin.id, variant) {
        case (_, .primary): return skin.palette.accent
        case (.eightBall, .dismiss): return skin.palette.surface
        case (.prizeWheel, .dismiss): return skin.palette.background
        // A frosted disc: white over the reveal's cyan.
        case (.gashapon, .dismiss): return .white.opacity(0.55)
        case (_, .secondary): return skin.palette.surface
        }
    }

    private var borderWidth: CGFloat {
        switch skin.id {
        case .prizeWheel: return variant == .primary ? 3 : 2.5
        case .eightBall, .gashapon: return 0
        }
    }

    private var shadow: SkinShadowStyle {
        guard variant == .primary else { return .none }
        switch skin.id {
        case .prizeWheel: return .hard(offset: CGSize(width: 3, height: 3), color: skin.palette.primaryText)
        case .gashapon: return .soft(radius: 7, x: 0, y: 6, color: skin.palette.accent, opacity: 0.6)
        case .eightBall: return .none
        }
    }
}
