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
                .indShadow(shadow, cornerRadius: cornerRadius)
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

    private var style: SkinIconButtonStyle { skin.shape.iconButton }

    private var shape: AnyShape {
        switch style.shape {
        case .circle:
            return AnyShape(Circle())
        case let .roundedSquare(cornerFraction):
            return AnyShape(RoundedRectangle(cornerRadius: size * cornerFraction, style: .continuous))
        }
    }

    /// The radius a `.hard` shadow needs to draw its offset copy in the same
    /// outline as the button.
    private var cornerRadius: CGFloat {
        switch style.shape {
        case .circle: return size / 2
        case let .roundedSquare(cornerFraction): return size * cornerFraction
        }
    }

    // `foreground` and `background` are internal (not `private`) so
    // `ContrastTests` can check the reveal's "✕" against its own disc.
    var foreground: Color {
        switch variant {
        case .primary: return skin.palette.onAccent
        case .dismiss: return skin.reveal.dismiss.foreground
        case .secondary: return skin.palette.secondaryText
        }
    }

    var background: Color {
        switch variant {
        case .primary: return skin.palette.accent
        case .dismiss: return skin.reveal.dismiss.background
        case .secondary: return skin.palette.surface
        }
    }

    private var borderWidth: CGFloat {
        variant == .primary ? style.primaryBorderWidth : style.quietBorderWidth
    }

    private var shadow: SkinShadowStyle {
        variant == .primary ? style.primaryShadow : .none
    }
}
