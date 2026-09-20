import XCTest
import SwiftUI
@testable import IndecisiveKit

/// Locks in PLAN.md Phase 6's contrast fixes as a regression test — a
/// future token change that silently drops a color back below WCAG AA
/// should fail a fast unit test, not wait for someone to eyeball it.
@MainActor
final class ContrastTests: XCTestCase {

    private func luminance(of color: Color) -> Double {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        func linearize(_ c: CGFloat) -> Double {
            let c = Double(c)
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)
    }

    /// WCAG 2.1 contrast ratio: (L1+0.05)/(L2+0.05), lighter over darker.
    private func contrastRatio(_ a: Color, _ b: Color) -> Double {
        let l1 = luminance(of: a), l2 = luminance(of: b)
        let lighter = max(l1, l2), darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// The colour the eye actually sees when `color` — possibly translucent — is
    /// painted over an opaque `backdrop`. Gashapon's frosted "✕" disc and cream
    /// "One more turn" button are translucent, so their raw tint isn't what to test.
    private func flattened(_ color: Color, over backdrop: Color) -> Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
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
            XCTAssertGreaterThanOrEqual(ratio, 3.0, "\(skin.name) chevron-on-surface contrast is \(ratio), fails WCAG AA for a UI component")
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
    /// otherwise checks anything against. 14pt extrabold / 16pt display
    /// both qualify as WCAG "large text", so 3:1 is the applicable bar.
    func testRevealKickerMeetsAALargeTextContrastOnRevealBackground() {
        for skin in Skin.all {
            let ratio = contrastRatio(skin.reveal.kicker.color, skin.palette.revealBackground)
            XCTAssertGreaterThanOrEqual(ratio, 3.0, "\(skin.name) reveal kicker contrast is \(ratio), fails WCAG AA large text")
        }
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
            XCTAssertGreaterThanOrEqual(ratio, 3.0, "\(skin.name) reveal dismiss glyph contrast is \(ratio), fails WCAG AA for a UI component")
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
