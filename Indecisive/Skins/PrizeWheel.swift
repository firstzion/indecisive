import SwiftUI

extension Skin {
    /// 1c — fairground stickers, hard black outlines, wedges everywhere.
    static let prizeWheel: Skin = {
        let palette = SkinPalette(
            background: Color(hex: 0xFBF3E4),
            surface: Color(hex: 0xFFFFFF),
            surfaceBorder: Color(hex: 0x17130F),
            primaryText: Color(hex: 0x17130F),
            secondaryText: Color(hex: 0x6E655B),
            // Darkened from the design's #7C7167 (4.31:1 on #FBF3E4, fails
            // WCAG AA's 4.5:1 for normal text) — not one of PLAN.md's two
            // named risk spots, but the same audit catches it too.
            tertiaryText: Color(hex: 0x726557),
            chevron: Color(hex: 0x17130F),
            divider: Color(hex: 0x17130F),
            dashedBorder: Color(hex: 0xC9B89C),
            accent: Color(hex: 0xF0503C),
            onAccent: Color(hex: 0xFBF3E4),
            // Today's look, made explicit: what `Color.red` resolves to in a light
            // scheme on iOS 26. 3.6:1 with white on it and on the white card surface.
            destructive: Color(hex: 0xFF383C),
            onDestructive: .white,
            flavors: [0xF0503C, 0xFFC93C, 0x1F9E8E, 0xFBF3E4].map { Color(hex: $0) },
            revealBackground: Color(hex: 0xFFC93C),
            colorScheme: .light
        )
        let type = SkinTypography(
            display: [
                .regular: "TitanOne", .medium: "TitanOne", .semibold: "TitanOne",
                .bold: "TitanOne", .extrabold: "TitanOne", .black: "TitanOne",
            ],
            body: [
                .regular: "WorkSans-Regular", .medium: "WorkSansRoman-Medium",
                .semibold: "WorkSansRoman-SemiBold", .bold: "WorkSansRoman-Bold",
                .extrabold: "WorkSansRoman-ExtraBold",
            ],
            mono: [.regular: "DMMono-Regular", .medium: "DMMono-Medium"],
            // Titan One reads too heavy at list-row density, so compact titles drop to
            // Work Sans. This matches the source design exactly: the Wheel's home-row list
            // names and dashed rows are Work Sans, while its big detail headline and CTA
            // are still Titan One.
            compactTitle: .body
        )
        // The spin decelerates onto the winner's wedge over `spinDuration`, and the name
        // card is on screen 0.1s after it lands. The animation, the haptics and VoiceOver's
        // announcement all run off these numbers.
        let spinDuration = 2.8
        let motion = SkinMotion(
            revealIntro: .spin(duration: spinDuration, turns: 4, cardIn: 0.1),
            // Selection ticks that slow as the wheel does, then the success tap as it lands.
            revealHaptics: HapticBeat.decelerating(over: spinDuration)
                + [HapticBeat(at: spinDuration, kind: .success)],
            heroBadge: .spin(period: 9),
            // The mini wheel on the button turns once every 2.4s.
            ctaGlyph: .spin(period: 2.4),
            // The Wheel's "SPIN AGAIN" has no glyph in the source design.
            rerollGlyph: .none,
            revealBackdrop: .none
        )
        return Skin(
            id: .prizeWheel,
            name: "Prize Wheel",
            tagline: "Fairground stickers, hard black outlines, wedges everywhere.",
            palette: palette,
            type: type,
            shape: SkinShape(
                cardRadius: 18,
                cardBorderWidth: 3,
                cardShadow: .hard(offset: CGSize(width: 4, height: 4), color: palette.primaryText),
                dashedBorderWidth: 3,
                dashedCornerRadius: 18,
                ctaHeight: 68,
                ctaCornerRadius: 20,
                ctaBorderWidth: 3,
                ctaShadow: .hard(offset: CGSize(width: 5, height: 5), color: palette.primaryText),
                ctaInsetShadow: nil,
                iconButton: SkinIconButtonStyle(
                    shape: .roundedSquare(cornerFraction: 0.32),
                    primaryBorderWidth: 3,
                    quietBorderWidth: 2.5,
                    primaryShadow: .hard(offset: CGSize(width: 3, height: 3), color: palette.primaryText)
                )
            ),
            copy: SkinCopy(
                homeSubtitle: { _ in "Step right up, pick a wheel" },
                countLine: { n in "\(n) wedge\(n == 1 ? "" : "s")" },
                newListRow: "Build a new wheel",
                homeFooter: { _ in "Everybody wins. Eventually." },
                homeEmptyStateTitle: "No wheels yet",
                homeEmptyStateMessage: "Build your first wheel below to get spinning.",
                detailHeadline: { n in "\(n) wedge\(n == 1 ? "" : "s") loaded" },
                lastPickLine: { name, _ in "Last spin landed on \(name)" },
                addRow: "Add a wedge",
                ctaCaption: "Give it a whirl",
                ctaLabel: "PICK FOR ME",
                emptyStateTitle: "No wedges yet",
                emptyStateMessage: "Load it up before you give it a spin.",
                revealKicker: "WE HAVE A WINNER",
                revealSupport: { _ in "The wheel does not negotiate." },
                acceptLabel: "LOCK IT IN",
                rerollLabel: "SPIN AGAIN"
            ),
            motion: motion,
            reveal: SkinRevealStyle(
                colorScheme: .light,
                headerText: palette.primaryText,
                kicker: SkinRevealStyle.Kicker(
                    font: type.display(19),
                    color: palette.primaryText,
                    bottomClearance: 8
                ),
                dismiss: SkinRevealStyle.Dismiss(
                    foreground: palette.primaryText,
                    background: palette.background
                ),
                nameCard: SkinRevealStyle.NameCard(
                    fill: palette.surface,
                    border: SkinBorder(color: palette.primaryText, width: 4),
                    shadow: .hard(offset: CGSize(width: 6, height: 6), color: palette.primaryText),
                    horizontalInset: 0,
                    // The spin has to land before the name appears.
                    appearance: .afterIntro
                ),
                actions: SkinRevealStyle.Actions(
                    axis: .horizontal,
                    accept: SkinRevealStyle.ActionButton(
                        fontSize: 19,
                        minHeight: 60,
                        corners: .rounded(18),
                        foreground: palette.background,
                        // Bespoke — coincides with `palette.flavors[2]`, but "the accept
                        // button's color" isn't really "flavour #3", so this keeps its own
                        // literal rather than reading that array.
                        background: Color(hex: 0x1F9E8E),
                        border: SkinBorder(color: palette.primaryText, width: 3),
                        shadow: .hard(offset: CGSize(width: 4, height: 4), color: palette.primaryText)
                    ),
                    reroll: SkinRevealStyle.ActionButton(
                        fontSize: 19,
                        minHeight: 60,
                        corners: .rounded(18),
                        foreground: palette.primaryText,
                        background: palette.background,
                        border: SkinBorder(color: palette.primaryText, width: 3),
                        shadow: .hard(offset: CGSize(width: 4, height: 4), color: palette.primaryText)
                    )
                ),
                confetti: SkinRevealStyle.ConfettiStyle(
                    colors: palette.flavors + [palette.surface],
                    cornerRadius: 3,
                    outline: palette.primaryText
                )
            ),
            traits: SkinTraits(shakeToPick: false)
        )
    }()
}
