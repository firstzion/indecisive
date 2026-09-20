import SwiftUI

extension Skin {
    /// 2a — capsule machine: chrome-white, two-tone capsules, crank the knob
    /// and see what drops.
    static let gashapon: Skin = {
        let palette = SkinPalette(
            background: Color(hex: 0xF2FAFF),
            surface: Color(hex: 0xFFFFFF),
            surfaceBorder: nil,
            primaryText: Color(hex: 0x16283C),
            secondaryText: Color(hex: 0x5A6E80),
            // Darkened from the design's #6C8497 (3.69:1 on #F2FAFF, fails
            // WCAG AA's 4.5:1 for normal text) — it sets the dashed add rows
            // and the Home footer.
            tertiaryText: Color(hex: 0x5F7486),
            // Darkened from the design's #B9CAD8 (1.68:1 on the card surface
            // #FFFFFF, fails WCAG AA's 3:1 for a UI component) — this renders
            // the "›" list-row indicator and the item-reorder arrows, both
            // read against `surface`, never `background`.
            chevron: Color(hex: 0x7798B4),
            divider: Color(hex: 0xE8F1F7),
            dashedBorder: Color(hex: 0xBFD6E4),
            // Darkened from the design's #FF5D8F (white on it is 2.91:1,
            // just short of WCAG AA's 3:1 for large text). The capsule
            // `flavors` below keep the design's exact pink; this is only the
            // shade that carries white text and glyphs.
            accent: Color(hex: 0xFA578B),
            onAccent: .white,
            // Today's look, made explicit: what `Color.red` resolves to in a light
            // scheme on iOS 26. 3.6:1 with white on it and on the white card surface.
            destructive: Color(hex: 0xFF383C),
            onDestructive: .white,
            flavors: [0xFF5D8F, 0x21C7E8, 0x4BE0B0, 0xFFD23D, 0xFF9F4D].map { Color(hex: $0) },
            revealBackground: Color(hex: 0x21C7E8),
            colorScheme: .light
        )
        let type = SkinTypography(
            // Mochiy Pop One ships a single weight; every semantic weight
            // resolves to it.
            display: [
                .regular: "MochiyPopOne-Regular", .medium: "MochiyPopOne-Regular",
                .semibold: "MochiyPopOne-Regular", .bold: "MochiyPopOne-Regular",
                .extrabold: "MochiyPopOne-Regular", .black: "MochiyPopOne-Regular",
            ],
            // Only M PLUS Rounded 1c's Medium (500) and Bold (700) are
            // bundled — the two weights the design uses. `.semibold` lands on
            // Medium: the app asks for it on secondary lines (counts,
            // captions), which the design sets in 500.
            body: [
                .regular: "RoundedMplus1c-Medium", .medium: "RoundedMplus1c-Medium",
                .semibold: "RoundedMplus1c-Medium", .bold: "RoundedMplus1c-Bold",
                .extrabold: "RoundedMplus1c-Bold", .black: "RoundedMplus1c-Bold",
            ],
            mono: [.regular: "DMMono-Regular", .medium: "DMMono-Medium"],
            // Gashapon's list names and dashed rows are M PLUS Rounded bold in the design;
            // Mochiy Pop One is kept for headlines and buttons.
            compactTitle: .body
        )
        // Two paints the palette has no slot for: the deep teal ink the reveal uses on its
        // cyan background (the rest of the skin uses navy), and the capsule's cream lower
        // half, which the reveal's name card and buttons reuse.
        let revealInk = Color(hex: 0x0B3D4C)
        let shell = CapsulePaint.shell
        // The mockup's `pfm-pop`, then `pfm-lid` 0.25s later. The animation, the haptics and
        // VoiceOver's announcement (the moment the lid has finished springing off) all run
        // off these numbers.
        let lidDelay = 0.25
        let lidSettle = 0.6
        let motion = SkinMotion(
            revealIntro: .popAndOpen(lidDelay: lidDelay, lidSettle: lidSettle),
            // Two crank ticks as the knob turns, a firmer bump as the lid pops, then the
            // success tap once the prize is showing. Spaced apart: back-to-back haptics
            // get swallowed.
            revealHaptics: [
                HapticBeat(at: 0, kind: .impact(.rigid, intensity: 1)),
                HapticBeat(at: 0.1, kind: .impact(.rigid, intensity: 0.7)),
                HapticBeat(at: lidDelay, kind: .impact(.medium, intensity: 1)),
                HapticBeat(at: lidSettle, kind: .success),
            ],
            // The mockup's 3.4s float, each half of it here.
            heroBadge: .float(distance: 10, halfPeriod: 1.7),
            // The machine's knob turns once every 3s, like the mockup's.
            ctaGlyph: .spin(period: 3),
            rerollGlyph: .wiggle(degrees: 4, halfPeriod: 0.6),
            // The sunburst turns once every 26s.
            revealBackdrop: .spin(period: 26)
        )
        return Skin(
            id: .gashapon,
            name: "Gashapon",
            tagline: "Capsule machine, two-tone capsules, crank the knob and see what drops.",
            palette: palette,
            type: type,
            shape: SkinShape(
                cardRadius: 24,
                cardBorderWidth: 0,
                cardShadow: .soft(radius: 6, x: 0, y: 4, color: palette.primaryText, opacity: 0.14),
                dashedBorderWidth: 2.5,
                dashedCornerRadius: 24,
                ctaHeight: 68,
                ctaCornerRadius: 34,
                ctaBorderWidth: 0,
                ctaShadow: .soft(radius: 14, x: 0, y: 10, color: palette.accent, opacity: 0.6),
                ctaInsetShadow: SkinInsetShadow(color: .black.opacity(0.12), x: 0, y: -4),
                iconButton: SkinIconButtonStyle(
                    shape: .circle,
                    primaryBorderWidth: 0,
                    quietBorderWidth: 0,
                    primaryShadow: .soft(radius: 7, x: 0, y: 6, color: palette.accent, opacity: 0.6)
                )
            ),
            copy: SkinCopy(
                homeSubtitle: { n in "\(n) machine\(n == 1 ? "" : "s") loaded · ¥0 per turn" },
                countLine: { n in "\(n) capsule\(n == 1 ? "" : "s") inside" },
                newListRow: "Install a new machine",
                homeFooter: { _ in "One turn per crisis. No refunds." },
                homeEmptyStateTitle: "No machines yet",
                homeEmptyStateMessage: "Tap below to install your first one.",
                detailHeadline: { n in "\(n) in the dome" },
                lastPickLine: { name, date in
                    "Last drop: \(name), \(date.formatted(.dateTime.weekday(.wide)))"
                },
                addRow: "Load another capsule",
                ctaCaption: "Turn the knob, trust the dome",
                ctaLabel: "Pick For Me",
                emptyStateTitle: "The dome is empty",
                emptyStateMessage: "Load a few capsules before you can turn the knob.",
                revealKicker: "CAPSULE CRACKED",
                revealWinnerLabel: "YOU GOT",
                revealSupport: { n in "1 of \(n) · duplicate protection off" },
                acceptLabel: "Keeping it",
                rerollLabel: "One more turn"
            ),
            motion: motion,
            reveal: SkinRevealStyle(
                colorScheme: .light,
                headerText: revealInk,
                kicker: SkinRevealStyle.Kicker(
                    font: type.display(15),
                    color: revealInk,
                    bottomClearance: 0
                ),
                dismiss: SkinRevealStyle.Dismiss(
                    foreground: revealInk,
                    // A frosted disc: white over the reveal's cyan.
                    background: .white.opacity(0.55)
                ),
                nameCard: SkinRevealStyle.NameCard(
                    fill: shell,
                    border: nil,
                    // A flat shelf of teal under the card, like the mockup's
                    // `0 14px 0 rgba(11,61,76,.2)`.
                    shadow: .hard(offset: CGSize(width: 0, height: 14), color: revealInk.opacity(0.2)),
                    // The mockup sets the whole middle stack in from the screen edges.
                    horizontalInset: 26,
                    appearance: .withCentrepiece
                ),
                actions: SkinRevealStyle.Actions(
                    axis: .vertical,
                    accept: SkinRevealStyle.ActionButton(
                        fontSize: 20,
                        minHeight: 62,
                        corners: .pill,
                        foreground: shell,
                        background: palette.primaryText,
                        border: nil,
                        shadow: .none
                    ),
                    reroll: SkinRevealStyle.ActionButton(
                        fontSize: 18,
                        minHeight: 56,
                        corners: .pill,
                        foreground: revealInk,
                        background: shell.opacity(0.92),
                        border: nil,
                        shadow: .none
                    )
                ),
                confetti: SkinRevealStyle.ConfettiStyle(
                    // Its cyan flavour would vanish against its cyan reveal background, so
                    // it uses the mockup's own mix of yellow, cream, pink and mint instead.
                    colors: [CapsulePaint.prize, shell, palette.flavors[0], palette.flavors[2]],
                    cornerRadius: 3,
                    outline: nil
                )
            ),
            traits: SkinTraits(shakeToPick: false)
        )
    }()
}
