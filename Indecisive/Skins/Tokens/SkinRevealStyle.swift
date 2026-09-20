import SwiftUI

/// A stroke round a shape. Where a token holds an optional one, `nil` means
/// "no border".
struct SkinBorder: Sendable {
    let color: Color
    let width: CGFloat
}

/// How a button's corners are rounded.
enum SkinCorners: Sendable {
    /// Fully rounded ends: half the button's own height.
    case pill
    case rounded(CGFloat)

    func radius(forHeight height: CGFloat) -> CGFloat {
        switch self {
        case .pill: return height / 2
        case let .rounded(radius): return radius
        }
    }
}

/// Everything about the reveal screen that differs between skins.
///
/// The reveal sits on its own loud background (`palette.revealBackground` —
/// near-black, bright yellow, cyan), so its text, buttons and confetti each
/// pick colours that read there; they aren't derivable from the palette's
/// Home/Detail colours. Every field is required — a new skin can't reach the
/// reveal screen without deciding each one — and the colours are resolved
/// values, built in the skin's own file from its own palette.
struct SkinRevealStyle: Sendable {
    /// Whether the reveal reads as a light or dark screen (`.preferredColorScheme`).
    /// Chosen with the reveal background, not derived from `palette.colorScheme`.
    let colorScheme: ColorScheme
    /// The list's name in the header, over `palette.revealBackground`.
    let headerText: Color
    let kicker: Kicker
    let dismiss: Dismiss
    /// The card the winner's name sits in below the centrepiece. `nil` for a
    /// skin whose centrepiece shows the name itself (the 8-Ball's diamond
    /// window) — an optional, so a new skin has to say which it is.
    let nameCard: NameCard?
    /// The support line ("Chosen from 14. …") set straight onto the reveal background under
    /// the centrepiece, for a skin with no name card to hold it (the 8-Ball, Crystal Ball). A
    /// skin with a card has the card draw the line inside itself, so this is `nil` there — every
    /// skin says it exactly once, and none says it twice.
    let supportLine: SupportLine?
    let actions: Actions
    let confetti: ConfettiStyle

    /// The eyebrow line above the centrepiece ("THE BALL HAS SPOKEN").
    struct Kicker: Sendable {
        let font: Font
        let color: Color
        /// Extra space under the kicker. The Wheel's pointer overlaps the
        /// centrepiece below it, so it needs a little clearance to keep the two
        /// from colliding; the others don't.
        let bottomClearance: CGFloat
    }

    /// The "✕" that closes the reveal.
    struct Dismiss: Sendable {
        let foreground: Color
        /// The disc behind the glyph. May be translucent (Gashapon's is a
        /// frosted white), so contrast is judged after flattening it over
        /// `palette.revealBackground`.
        let background: Color
    }

    struct NameCard: Sendable {
        /// When the card shows, relative to the centrepiece's intro animation.
        enum Appearance: Sendable {
            /// It pops in with the centrepiece.
            case withCentrepiece
            /// It is held back until the intro finishes — the Wheel's spin has
            /// to land before the name appears.
            case afterIntro
        }

        let fill: Color
        let border: SkinBorder?
        let shadow: SkinShadowStyle
        /// Space either side, narrowing the card from the full width.
        let horizontalInset: CGFloat
        let appearance: Appearance
    }

    /// A support line drawn on the reveal background itself (see `supportLine`).
    struct SupportLine: Sendable {
        let font: Font
        /// Read straight against `palette.revealBackground`.
        let color: Color
    }

    /// The accept / re-roll buttons below the centrepiece.
    struct Actions: Sendable {
        /// `.vertical` stacks two full-width buttons; `.horizontal` sets them
        /// side by side — a real layout difference, not just a colour change.
        let axis: Axis
        let accept: ActionButton
        let reroll: ActionButton
    }

    struct ActionButton: Sendable {
        let fontSize: CGFloat
        /// A minimum: the label can push the button taller at large Dynamic
        /// Type sizes.
        let minHeight: CGFloat
        let corners: SkinCorners
        let foreground: Color
        /// May be translucent (Gashapon's re-roll is a near-opaque cream), so
        /// contrast is judged after flattening it over `palette.revealBackground`.
        let background: Color
        let border: SkinBorder?
        let shadow: SkinShadowStyle
    }

    /// The skin's celebration behind the reveal: falling confetti, or twinkling stars.
    /// Falling confetti is hidden under Reduce Motion — which is how the snapshot tests
    /// run — so no image pins it; twinkling stars are drawn still instead, so those show.
    /// `SkinBehaviourTests` pins the look and `ConfettiTests` the motion.
    struct ConfettiStyle: Sendable {
        enum Motion: Sendable, Equatable {
            /// Pieces drop from above the top edge to below the bottom, spinning, again
            /// and again — the mockup's `pfm-fall`.
            case falling
            /// Stars hold their places and swell and fade in turn — the mockup's
            /// `pfm-twinkle` (Crystal Ball). There are six, in the mockup's own places.
            case twinkling
        }

        let motion: Motion
        /// The colours the pieces cycle through. Must not be empty.
        let colors: [Color]
        /// Corner radius of the rectangular pieces (the round ones are circles). Falling
        /// confetti only: twinkling stars are always discs.
        let cornerRadius: CGFloat
        /// Ink colour of the outline drawn round every piece; `nil` draws none. Falling
        /// confetti only.
        let outline: Color?
    }
}
