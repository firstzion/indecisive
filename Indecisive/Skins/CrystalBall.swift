import SwiftUI

extension Skin {
    /// 2b — fortune-teller's parlour: plum velvet, gold trim, mist that parts to show your fate.
    static let crystalBall: Skin = {
        let palette = SkinPalette(
            background: Color(hex: 0x2C1148),
            surface: Color(hex: 0x3A1A5C),
            surfaceBorder: Color(hex: 0x533177),
            primaryText: Color(hex: 0xF7EDFF),
            // The one skin whose Home title isn't its primary text: the mockup sets it in gold.
            titleText: CrystalPaint.gold,
            secondaryText: Color(hex: 0xC0A7DC),
            tertiaryText: Color(hex: 0xA98BC9),
            chevron: Color(hex: 0x8B6DAE),
            divider: Color(hex: 0x4A2A69),
            dashedBorder: Color(hex: 0x5E3985),
            accent: CrystalPaint.gold,
            onAccent: Color(hex: 0x2C1148),
            // What `Color.red` resolves to in a dark scheme on iOS 26, as on the 8-Ball: 4.1:1 on
            // this skin's card surface and 3.4:1 with white on it (`ContrastTests`).
            // The gold reads at 10.4:1 on the deep purple background.
            accentText: CrystalPaint.gold,
            destructive: Color(hex: 0xFF4245),
            onDestructive: .white,
            // The orbs' bright centres; their deeper rims are the art's (`CrystalPaint.tints`).
            flavors: CrystalPaint.tints.map(\.light),
            revealBackground: Color(hex: 0x1C0830),
            colorScheme: .dark
        )
        let type = SkinTypography(
            // Bagel Fat One ships a single weight; every semantic weight resolves to it.
            display: [
                .regular: "BagelFatOne-Regular", .medium: "BagelFatOne-Regular",
                .semibold: "BagelFatOne-Regular", .bold: "BagelFatOne-Regular",
                .extrabold: "BagelFatOne-Regular", .black: "BagelFatOne-Regular",
            ],
            // Nunito is the whole family, so each weight is the real thing. The mockup uses
            // SemiBold (600) for secondary lines and Bold (700) for labels.
            body: [
                .regular: "Nunito-Regular", .medium: "Nunito-Medium",
                .semibold: "Nunito-SemiBold", .bold: "Nunito-Bold",
                .extrabold: "Nunito-ExtraBold", .black: "Nunito-Black",
            ],
            // Unused by this skin; the mockups' mono face is the 8-Ball's alone.
            mono: [.regular: "DMMono-Regular", .medium: "DMMono-Medium"],
            // Unlike Gashapon and the Wheel, the mockup keeps Bagel Fat One for list names and the
            // dashed rows.
            compactTitle: .display
        )
        // The ball pops in with its answer hidden; `partDelay` later the mist parts and the
        // name fades in over `nameFadeIn`. The mockup has only the pop (`pfm-pop`) and the
        // mist's endless drift (`pfm-mist`) — this sequence is the tagline's "mist that parts to
        // show your fate", and so is my choice. The animation, the haptics and VoiceOver's
        // announcement all run off these numbers.
        let partDelay = 0.5
        let nameFadeIn = 0.5
        let motion = SkinMotion(
            revealIntro: .mistParts(partDelay: partDelay, nameFadeIn: nameFadeIn),
            // A soft shimmer as the ball appears, a light tap as the mist parts, then the success
            // tap once the name is showing. Spaced apart: back-to-back haptics get swallowed.
            revealHaptics: [
                HapticBeat(at: 0, kind: .impact(.soft, intensity: 0.9)),
                HapticBeat(at: 0.16, kind: .impact(.soft, intensity: 0.5)),
                HapticBeat(at: 0.32, kind: .impact(.soft, intensity: 0.7)),
                HapticBeat(at: partDelay, kind: .impact(.light, intensity: 1)),
                HapticBeat(at: partDelay + nameFadeIn, kind: .success),
            ],
            // The mockup's `pfm-float`: 3.6s on the hero orb, 2.6s on the button's bead, 10pt each.
            heroBadge: .float(distance: 10, halfPeriod: 1.8),
            ctaGlyph: .float(distance: 10, halfPeriod: 1.3),
            // `pfm-twinkle` at 1.6s: 0.6 of its size and 0.35 of its opacity at the dimmest.
            rerollGlyph: .twinkle(scaleLow: 0.6, opacityLow: 0.35, halfPeriod: 0.8),
            // `pfm-glow` at 3s: opacity .45 to 1.
            revealBackdrop: .pulse(low: 0.45, halfPeriod: 1.5)
        )
        return Skin(
            id: .crystalBall,
            name: "Crystal Ball",
            tagline: "Fortune-teller parlour: plum velvet, gold trim, mist that parts to show your fate.",
            palette: palette,
            type: type,
            shape: SkinShape(
                cardRadius: 22,
                cardBorderWidth: 1,
                cardShadow: .none,
                dashedBorderWidth: 2,
                dashedCornerRadius: 22,
                ctaHeight: 68,
                ctaCornerRadius: 34,
                ctaBorderWidth: 0,
                // The mockup's `0 0 34px -8px` gold halo. A SwiftUI glow has no spread, so this
                // is the nearest match, fitted numerically to the CSS shadow's profile (a
                // little under half the strength, at a bit under the blur's radius).
                ctaShadow: .glow(color: palette.accent, radius: 15.5, opacity: 0.47),
                // `inset 0 -4px 0 rgba(0,0,0,.14)`.
                ctaInsetShadow: SkinInsetShadow(color: .black.opacity(0.14), x: 0, y: -4),
                iconButton: SkinIconButtonStyle(
                    shape: .circle,
                    primaryBorderWidth: 0,
                    quietBorderWidth: 0,
                    // `0 0 22px -6px` on the "+", matched the same way.
                    primaryShadow: .glow(color: palette.accent, radius: 9.5, opacity: 0.36)
                )
            ),
            copy: SkinCopy(
                homeSubtitle: { _ in "Madame Random will see you now" },
                countLine: { n in "\(n) possible future\(n == 1 ? "" : "s")" },
                newListRow: "Summon a new list",
                homeFooter: { _ in "The mists are ready when you are" },
                homeEmptyStateTitle: "The parlour is quiet",
                homeEmptyStateMessage: "Summon your first list below and the mists will do the rest.",
                detailHeadline: { n in "\(n) future\(n == 1 ? "" : "s") inside" },
                lastPickLine: { name, _ in "The mists last chose \(name)" },
                addRow: "Add to the prophecy",
                ctaCaption: "Cross my palm and tap",
                ctaLabel: "Pick For Me",
                emptyStateTitle: "No futures to foresee",
                emptyStateMessage: "Add a few possibilities before you consult the mists.",
                revealKicker: "THE MISTS HAVE PARTED",
                // The mockup breaks the line after "were".
                revealSupport: { n in "Chosen from \(n). The spirits were\nunanimous, which never happens." },
                acceptLabel: "So it is written",
                rerollLabel: "Consult again"
            ),
            motion: motion,
            reveal: SkinRevealStyle(
                colorScheme: .dark,
                headerText: palette.secondaryText,
                kicker: SkinRevealStyle.Kicker(
                    font: type.body(13, weight: .semibold),
                    color: palette.accent,
                    bottomClearance: 0
                ),
                dismiss: SkinRevealStyle.Dismiss(
                    foreground: palette.primaryText,
                    background: palette.surface
                ),
                // No card: the name sits inside the ball, and the support line below it is set
                // straight onto the background.
                nameCard: nil,
                supportLine: SkinRevealStyle.SupportLine(
                    font: type.body(14, weight: .semibold),
                    color: palette.secondaryText
                ),
                backdropTint: CrystalPaint.pink,
                rerollGlyphTint: CrystalPaint.pink,
                actions: SkinRevealStyle.Actions(
                    axis: .vertical,
                    accept: SkinRevealStyle.ActionButton(
                        fontSize: 20,
                        minHeight: 62,
                        corners: .pill,
                        foreground: palette.onAccent,
                        background: palette.accent,
                        border: nil,
                        // `0 0 34px -10px`, matched as the button's halo above is.
                        shadow: .glow(color: palette.accent, radius: 14.5, opacity: 0.38)
                    ),
                    reroll: SkinRevealStyle.ActionButton(
                        fontSize: 18,
                        minHeight: 56,
                        corners: .pill,
                        foreground: palette.primaryText,
                        // The mockup fills it with the Home/Detail background, over the reveal's
                        // darker one, and rings it in the dashed rows' violet.
                        background: palette.background,
                        border: SkinBorder(color: palette.dashedBorder, width: 1.5),
                        shadow: .none
                    )
                ),
                // Stars, not confetti: six that twinkle in place, in the mockup's colours in the
                // mockup's order (gold, cyan, pink, gold, pale, pink).
                confetti: SkinRevealStyle.ConfettiStyle(
                    motion: .twinkling,
                    colors: [
                        CrystalPaint.gold, CrystalPaint.cyan, CrystalPaint.pink,
                        CrystalPaint.gold, CrystalPaint.starlight, CrystalPaint.pink,
                    ],
                    cornerRadius: 0,
                    outline: nil
                )
            ),
            traits: SkinTraits(shakeToPick: false)
        )
    }()
}
