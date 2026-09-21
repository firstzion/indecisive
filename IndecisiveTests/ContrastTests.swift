import XCTest
import SwiftUI
@testable import IndecisiveKit

/// Locks in PLAN.md Phase 6's contrast fixes as a regression test — a
/// future token change that silently drops a color back below WCAG AA
/// should fail a fast unit test, not wait for someone to eyeball it.
@MainActor
final class ContrastTests: XCTestCase {

    private func luminance(of color: Color) -> Double {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        func linearize(_ c: CGFloat) -> Double {
            let c = Double(c)
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)
    }

    /// WCAG 2.1 contrast ratio: (L1+0.05)/(L2+0.05), lighter over darker.
    private func contrastRatio(_ a: Color, _ b: Color) -> Double {
        let l1 = luminance(of: a)
        let l2 = luminance(of: b)
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// The colour the eye actually sees when `color` — possibly translucent — is
    /// painted over an opaque `backdrop`. Gashapon's frosted "✕" disc and cream
    /// "One more turn" button are translucent, so their raw tint isn't what to test.
    private func flattened(_ color: Color, over backdrop: Color) -> Color {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        var br: CGFloat = 0
        var bg: CGFloat = 0
        var bb: CGFloat = 0
        var ba: CGFloat = 0
        UIColor(backdrop).getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        return Color(
            .sRGB,
            red: Double(r * a + br * (1 - a)),
            green: Double(g * a + bg * (1 - a)),
            blue: Double(b * a + bb * (1 - a)),
            opacity: 1
        )
    }

    /// WCAG AA for normal-size body text: 4.5:1. This is where the design
    /// actually failed — see PLAN.md §4.4 for the one the plan itself
    /// flagged for the 8-Ball; the Wheel's was found the same way.
    func testTertiaryTextMeetsAANormalTextContrastOnBackground() {
        for skin in Skin.all {
            let ratio = contrastRatio(skin.palette.tertiaryText, skin.palette.background)
            XCTAssertGreaterThanOrEqual(ratio, 4.5, "\(skin.name) tertiaryText contrast is \(ratio), fails WCAG AA")
        }
    }

    func testSecondaryTextMeetsAANormalTextContrastOnBackground() {
        for skin in Skin.all {
            let ratio = contrastRatio(skin.palette.secondaryText, skin.palette.background)
            XCTAssertGreaterThanOrEqual(ratio, 4.5, "\(skin.name) secondaryText contrast is \(ratio), fails WCAG AA")
        }
    }

    func testPrimaryTextMeetsAANormalTextContrastOnBackground() {
        for skin in Skin.all {
            let ratio = contrastRatio(skin.palette.primaryText, skin.palette.background)
            XCTAssertGreaterThanOrEqual(ratio, 4.5, "\(skin.name) primaryText contrast is \(ratio), fails WCAG AA")
        }
    }

    /// `onAccent` is only ever set on large, bold text (the 22pt extrabold
    /// CTA label) or icon glyphs, never normal body text — WCAG AA's
    /// threshold for that is 3:1, not 4.5:1. (Checked: the Wheel's is
    /// 3.22:1 — it passes 3:1 but would fail 4.5:1, which would be holding
    /// this pair to a standard that doesn't apply to how it's actually
    /// used.)
    func testOnAccentMeetsAALargeTextContrastOnAccent() {
        for skin in Skin.all {
            let ratio = contrastRatio(skin.palette.onAccent, skin.palette.accent)
            XCTAssertGreaterThanOrEqual(ratio, 3.0, "\(skin.name) onAccent-on-accent contrast is \(ratio), fails WCAG AA large text")
        }
    }

    /// `chevron` always renders on `surface`, never `background` directly —
    /// see `ListCard`'s "›" and `ItemRow`'s reorder arrows, both inside a
    /// `.indCard`. Neither of those is small text, so 3:1 (a UI component)
    /// is the right bar here; the 8-Ball's stricter text-only use is
    /// checked separately below.
    func testChevronMeetsAAUIComponentContrastOnSurface() {
        for skin in Skin.all {
            let ratio = contrastRatio(skin.palette.chevron, skin.palette.surface)
            XCTAssertGreaterThanOrEqual(
                ratio, 3.0, "\(skin.name) chevron-on-surface contrast is \(ratio), fails WCAG AA for a UI component")
        }
    }

    /// The 8-Ball is the one skin where `chevron` is also genuine text:
    /// `RowMarker` renders each item's "01"/"02"/… index in this color, so
    /// it needs the full 4.5:1 normal-text bar, not just the 3:1 a purely
    /// decorative arrow could get away with.
    func testEightBallChevronMeetsAANormalTextContrastOnSurfaceForRowMarkerIndices() {
        let ratio = contrastRatio(Skin.eightBall.palette.chevron, Skin.eightBall.palette.surface)
        XCTAssertGreaterThanOrEqual(ratio, 4.5, "8-Ball chevron-on-surface contrast is \(ratio), fails WCAG AA normal text")
    }

    /// `RevealKicker`'s eyebrow line sits on the reveal screen's own
    /// background, which is its own token (`revealBackground`) — often much
    /// louder than `skin.palette.background` — not one `ContrastTests`
    /// otherwise checks anything against.
    ///
    /// Held to the **normal-text** 4.5:1, not the 3:1 this used to use. The
    /// old bar was justified as "14pt extrabold / 16pt display both qualify
    /// as WCAG large text", which was true of the two skins that existed
    /// when it was written. Crystal Ball's kicker is 13pt semibold, which is
    /// neither ≥18pt regular nor ≥14pt bold, so large-text never applied to
    /// it. Every skin clears 4.5:1 today (5.8:1 to 16.8:1) — nothing was
    /// broken, the bar simply wouldn't have caught it if a colour moved.
    func testRevealKickerMeetsAANormalTextContrastOnRevealBackground() {
        for skin in Skin.all {
            let ratio = contrastRatio(skin.reveal.kicker.color, skin.palette.revealBackground)
            XCTAssertGreaterThanOrEqual(ratio, 4.5, "\(skin.name) reveal kicker contrast is \(ratio), fails WCAG AA")
        }
    }

    /// The accent-coloured controls on Home and Detail: the "‹ Lists" back
    /// button, "Edit"/"Done" and "Add", all set in `accentText` on
    /// `background`. 15–16pt bold, so WCAG's large-text 3:1 applies.
    ///
    /// Nothing covered this pair before. `accent` was only ever checked as a
    /// *fill* (`onAccent` on `accent`), and these are the same colour used as
    /// type on the screen behind it — which for Gashapon measured 2.93:1,
    /// failing AA on all three controls, on a toolbar that no snapshot drew
    /// until recently either.
    func testAccentTextMeetsAALargeTextContrastOnBackground() {
        for skin in Skin.all {
            let ratio = contrastRatio(skin.palette.accentText, skin.palette.background)
            XCTAssertGreaterThanOrEqual(
                ratio, 3.0,
                "\(skin.name) accentText contrast is \(ratio), fails WCAG AA large text")
        }
    }

    /// Text on a card, which is every list row on Home, every item row in a
    /// list, both empty states and the store-failure banner.
    ///
    /// Nothing covered this before: `primaryText` and `secondaryText` were
    /// only ever checked against `palette.background`, and cards are drawn on
    /// `palette.surface` — a different colour in all four skins.
    func testCardTextMeetsAANormalTextContrastOnSurface() {
        for skin in Skin.all {
            let primary = contrastRatio(skin.palette.primaryText, skin.palette.surface)
            XCTAssertGreaterThanOrEqual(
                primary, 4.5,
                "\(skin.name) primaryText on surface is \(primary), fails WCAG AA")

            let secondary = contrastRatio(skin.palette.secondaryText, skin.palette.surface)
            XCTAssertGreaterThanOrEqual(
                secondary, 4.5,
                "\(skin.name) secondaryText on surface is \(secondary), fails WCAG AA")
        }
    }

    // MARK: Confetti

    /// A falling piece with no outline is only visible by its fill, so a fill
    /// close to the background it falls on is a piece nobody sees. (Outlined
    /// confetti is exempt: the Wheel's fills are deliberately quiet and the
    /// ink outline carries them.)
    ///
    /// Gashapon is a known exception, listed rather than hidden: its mint sits
    /// at 1.21:1 on its cyan reveal background, unoutlined. That is the
    /// mockup's own pastel-on-cyan palette, so changing it is a design call —
    /// REVIEW.md P2-13.
    func testUnoutlinedConfettiCanActuallyBeSeen() {
        let knownExceptions: Set<SkinID> = [.gashapon]
        for skin in Skin.all
        where skin.reveal.confetti.motion == .falling
            && skin.reveal.confetti.outline == nil
            && !knownExceptions.contains(skin.id)
        {
            for colour in skin.reveal.confetti.colors {
                let ratio = contrastRatio(colour, skin.palette.revealBackground)
                XCTAssertGreaterThanOrEqual(
                    ratio, 2.0,
                    "\(skin.name) has an unoutlined confetti colour at \(ratio):1 on its reveal background — it will fall unseen"
                )
            }
        }
    }

    // MARK: The winner's name — the largest text in the app

    /// The reveal's name card: the winner's name, the little label above it
    /// (Gashapon's "YOU GOT") and the support line under it, each against the
    /// card's own fill.
    ///
    /// Nothing checked these before. `primaryText` was only ever tested
    /// against `palette.background`, which is a different colour from
    /// `card.fill` in both skins that have a card — so the single biggest
    /// piece of text in the app was the one pair with no coverage.
    func testNameCardTextMeetsContrastOnItsOwnCard() {
        var checked = 0
        for skin in Skin.all {
            guard let card = skin.reveal.nameCard else { continue }
            checked += 1

            // The winner's name is 34pt bold — comfortably WCAG "large text".
            let name = contrastRatio(skin.palette.primaryText, card.fill)
            XCTAssertGreaterThanOrEqual(name, 3.0, "\(skin.name) winner name contrast is \(name), fails WCAG AA large text")

            // The support line under it is 13pt: normal text.
            let support = contrastRatio(skin.palette.secondaryText, card.fill)
            XCTAssertGreaterThanOrEqual(support, 4.5, "\(skin.name) name-card support line contrast is \(support), fails WCAG AA")

            // And the 13pt label above it. Checked for every card, not only
            // the skins that show a label today: `labelColor` is required of
            // all of them, so a value that would fail the moment someone adds
            // the copy is worth catching now rather than then.
            let label = contrastRatio(card.labelColor, card.fill)
            XCTAssertGreaterThanOrEqual(label, 4.5, "\(skin.name) name-card label contrast is \(label), fails WCAG AA")
        }
        XCTAssertGreaterThan(checked, 0, "no skin has a name card to check")
    }

    /// The two skins that show the winner inside the centrepiece instead of on
    /// a card (`nameCard == nil`) draw it straight onto the reveal background:
    /// the 8-Ball's diamond window and Crystal Ball's orb. 30pt bold, so
    /// large text.
    func testInBallWinnerNameMeetsContrastOnTheRevealBackground() {
        var checked = 0
        for skin in Skin.all where skin.reveal.nameCard == nil {
            checked += 1
            let ratio = contrastRatio(skin.palette.accent, skin.palette.revealBackground)
            XCTAssertGreaterThanOrEqual(ratio, 3.0, "\(skin.name) in-ball winner name contrast is \(ratio), fails WCAG AA large text")
        }
        XCTAssertGreaterThan(checked, 0, "no skin shows its winner without a card")
    }

    // MARK: The rest of the reveal screen
    //
    // The kicker above is one of four things drawn straight onto
    // `revealBackground`. The others use one-off colours — a bespoke fill for
    // the Wheel's accept button, translucent whites for Gashapon's — that are
    // not palette tokens, so the token tests above never see them.

    /// The accept / re-roll labels are 18–22pt bold display type: WCAG "large
    /// text", so 3:1. The Wheel's accept button (`#FBF3E4` on `#1F9E8E`) clears it
    /// by less than 0.004 — this is what fails if either shade ever moves.
    func testRevealActionLabelsMeetAALargeTextContrastOnTheirButtons() {
        for skin in Skin.all {
            for role in [RevealActionRole.accept, .reroll] {
                let style = RevealActionStyle(skin: skin, role: role)
                let fill = flattened(style.background, over: skin.palette.revealBackground)
                let ratio = contrastRatio(style.foreground, fill)
                XCTAssertGreaterThanOrEqual(ratio, 3.0, "\(skin.name) \(role) label contrast is \(ratio), fails WCAG AA large text")
            }
        }
    }

    /// The header shows the list's name in 15pt bold. That's close enough to the
    /// "large text" line (WCAG measures it in points, not the pixels iOS points
    /// resemble) that it's held to the stricter normal-text bar, 4.5:1, instead.
    func testRevealHeaderTitleMeetsAANormalTextContrastOnRevealBackground() {
        for skin in Skin.all {
            let ratio = contrastRatio(skin.reveal.headerText, skin.palette.revealBackground)
            XCTAssertGreaterThanOrEqual(ratio, 4.5, "\(skin.name) reveal header contrast is \(ratio), fails WCAG AA")
        }
    }

    /// A loose support line ("Chosen from 14. …") is 14pt regular-weight text set straight onto the
    /// reveal background, so it is held to the normal-text bar. Only a skin with no name card has one.
    func testRevealSupportLineMeetsAANormalTextContrastOnRevealBackground() {
        var checked = 0
        for skin in Skin.all {
            guard let line = skin.reveal.supportLine else { continue }
            checked += 1
            let ratio = contrastRatio(line.color, skin.palette.revealBackground)
            XCTAssertGreaterThanOrEqual(ratio, 4.5, "\(skin.name) reveal support line contrast is \(ratio), fails WCAG AA")
        }
        XCTAssertGreaterThan(checked, 0, "no skin has a loose support line to check")
    }

    /// The "✕" glyph is a graphical control, so 3:1 (WCAG 1.4.11) against its disc.
    func testRevealDismissGlyphMeetsAAUIComponentContrastOnItsDisc() {
        for skin in Skin.all {
            let button = SkinIconButton(
                skin: skin, glyph: "✕", accessibilityLabel: "Close", variant: .dismiss, size: 32, action: {}
            )
            let disc = flattened(button.background, over: skin.palette.revealBackground)
            let ratio = contrastRatio(button.foreground, disc)
            XCTAssertGreaterThanOrEqual(
                ratio, 3.0, "\(skin.name) reveal dismiss glyph contrast is \(ratio), fails WCAG AA for a UI component")
        }
    }

    // MARK: Destructive controls
    //
    // Two places draw with `destructive`: the swipe-to-delete backdrop (a trash
    // glyph on the red) and edit mode's "minus" (the red, straight onto the list
    // card). Both are graphical controls, so 3:1 (WCAG 1.4.11). They used to be
    // raw `Color.red` / `.white` — outside the palette, so nothing checked them.

    func testDestructiveGlyphMeetsAAUIComponentContrastOnDestructive() {
        for skin in Skin.all {
            let ratio = contrastRatio(skin.palette.onDestructive, skin.palette.destructive)
            XCTAssertGreaterThanOrEqual(ratio, 3.0, "\(skin.name) trash glyph contrast is \(ratio), fails WCAG AA for a UI component")
        }
    }

    func testDestructiveMeetsAAUIComponentContrastOnSurface() {
        for skin in Skin.all {
            let ratio = contrastRatio(skin.palette.destructive, skin.palette.surface)
            XCTAssertGreaterThanOrEqual(ratio, 3.0, "\(skin.name) edit-mode minus contrast is \(ratio), fails WCAG AA for a UI component")
        }
    }
}
