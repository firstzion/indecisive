import SwiftUI

extension Skin {
    /// 1b — dark arcade cabinet, neon answers, the ball does the talking.
    static let eightBall: Skin = {
        let palette = SkinPalette(
            background: Color(hex: 0x140F2E),
            surface: Color(hex: 0x241B52),
            surfaceBorder: Color(hex: 0x362A72),
            primaryText: Color(hex: 0xF2EEFF),
            titleText: Color(hex: 0xF2EEFF),
            secondaryText: Color(hex: 0x9186C4),
            // Lightened from the design's #7C6FC0 (4.30:1 on #140F2E, fails
            // WCAG AA's 4.5:1 for normal text) — PLAN.md §4.4 flagged this
            // exact pair as a known risk spot.
            tertiaryText: Color(hex: 0x8479C7),
            // Lightened from the design's #5C4E9E (2.24:1 on the card
            // surface #241B52, fails WCAG AA's 4.5:1 for normal text) —
            // this is genuine text here, not just a decorative arrow:
            // `RowMarker` renders the "01"/"02"/… item indices in this
            // color, so it needs the full text-contrast bar rather than
            // the 3:1 a purely-graphical chevron/arrow could get away with.
            chevron: Color(hex: 0x958BC6),
            divider: Color(hex: 0x322766),
            dashedBorder: Color(hex: 0x3E3183),
            accent: Color(hex: 0xC8FF4D),
            onAccent: Color(hex: 0x140F2E),
            // Today's look, made explicit: what `Color.red` resolves to in a dark
            // scheme on iOS 26 (it was SwiftUI's own red before this was a token).
            // 3.4:1 with white on it, 4.5:1 on the card surface — `ContrastTests`.
            destructive: Color(hex: 0xFF4245),
            onDestructive: .white,
            flavors: [0xFF4FD8, 0x4DE1FF, 0xC8FF4D].map { Color(hex: $0) },
            revealBackground: Color(hex: 0x0B0818),
            colorScheme: .dark
        )
        let type = SkinTypography(
            display: [
                .regular: "LilitaOne", .medium: "LilitaOne", .semibold: "LilitaOne",
                .bold: "LilitaOne", .extrabold: "LilitaOne", .black: "LilitaOne",
            ],
            body: [
                .regular: "SpaceGrotesk-Light_Regular", .medium: "SpaceGrotesk-Light_Medium",
                .semibold: "SpaceGrotesk-Light_Medium", .bold: "SpaceGrotesk-Light_Bold",
            ],
            mono: [.regular: "DMMono-Regular", .medium: "DMMono-Medium"],
            // The 8-Ball keeps its display face even at compact sizes.
            compactTitle: .display
        )
        // The wobble is `wobbleSwings` round trips of `swingDuration` each way (1.08s in
        // all), then the answer fades in over 0.35s. The animation, the haptics and
        // VoiceOver's announcement all run off these numbers.
        let wobbleSwings = 6
        let swingDuration = 0.09
        let wobbleDuration = Double(wobbleSwings) * 2 * swingDuration
        let motion = SkinMotion(
            revealIntro: .wobble(swings: wobbleSwings, swingDuration: swingDuration, answerFadeIn: 0.35),
            // A rigid tap as the ball drops, weaker ticks through the first swings of the
            // wobble, then the success tap once it has finished.
            revealHaptics: [HapticBeat(at: 0, kind: .impact(.rigid, intensity: 1))]
                + (1..<wobbleSwings).map { HapticBeat(at: Double($0) * swingDuration, kind: .impact(.rigid, intensity: 0.6)) }
                + [HapticBeat(at: wobbleDuration, kind: .success)],
            heroBadge: .float(distance: 6, halfPeriod: 1.8),
            // The mini 8-ball on the button sits still.
            ctaGlyph: .none,
            rerollGlyph: .wiggle(degrees: 4, halfPeriod: 0.6),
            // PLAN.md §4.4's `ind-glow`: opacity .45 to 1 over a 2.6s round trip.
            revealBackdrop: .pulse(low: 0.45, halfPeriod: 1.3)
        )
        return Skin(
            id: .eightBall,
            name: "Midnight 8-Ball",
            tagline: "Dark arcade cabinet, neon answers, the ball does the talking.",
            palette: palette,
            type: type,
            shape: SkinShape(
                cardRadius: 20,
                cardBorderWidth: 1,
                cardShadow: .none,
                dashedBorderWidth: 2,
                dashedCornerRadius: 20,
                ctaHeight: 68,
                ctaCornerRadius: 34,
                ctaBorderWidth: 0,
                ctaShadow: .glow(color: palette.accent, radius: 24, opacity: 0.5),
                ctaInsetShadow: nil,
                iconButton: SkinIconButtonStyle(
                    shape: .circle,
                    primaryBorderWidth: 0,
                    quietBorderWidth: 0,
                    primaryShadow: .none
                )
            ),
            copy: SkinCopy(
                homeSubtitle: { _ in "ASK. SHAKE. OBEY." },
                countLine: { n in "\(n) item\(n == 1 ? "" : "s")" },
                newListRow: "Start a new list",
                homeFooter: { total in "THE BALL HAS SPOKEN \(total) TIME\(total == 1 ? "" : "S")" },
                homeEmptyStateTitle: "THE BALL IS WAITING",
                homeEmptyStateMessage: "Start a list below before you ask anything.",
                detailHeadline: { n in "\(n) CANDIDATE\(n == 1 ? "" : "S")" },
                lastPickLine: { name, _ in "Ball last said: \(name)" },
                addRow: "Throw one in the ring",
                ctaCaption: "THE 8-BALL KNOWS",
                ctaLabel: "PICK FOR ME",
                emptyStateTitle: "THE BALL IS EMPTY",
                emptyStateMessage: "Feed it a few answers before you ask.",
                revealKicker: "THE BALL HAS SPOKEN",
                revealSupport: { n in
                    let others = max(n - 1, 0)
                    return "Beat \(others) other contender\(others == 1 ? "" : "s"). Arguing with a ball is undignified."
                },
                acceptLabel: "LOCK IT IN",
                rerollLabel: "SHAKE AGAIN"
            ),
            motion: motion,
            reveal: SkinRevealStyle(
                colorScheme: .dark,
                headerText: palette.secondaryText,
                kicker: SkinRevealStyle.Kicker(
                    font: type.body(14, weight: .extrabold),
                    color: palette.accent,
                    bottomClearance: 0
                ),
                dismiss: SkinRevealStyle.Dismiss(
                    foreground: palette.primaryText,
                    background: palette.surface
                ),
                // No separate card: the winner's name appears inside the ball's
                // diamond window instead.
                nameCard: nil,
                // The mockup has a line under the ball ("Beat 13 other contenders. …"), but
                // the app has never drawn it — with no card there was nowhere for it to sit —
                // and this keeps the reveal exactly as it was. Setting a `SupportLine` here
                // would add it (Crystal Ball's is the model).
                supportLine: nil,
                actions: SkinRevealStyle.Actions(
                    axis: .vertical,
                    accept: SkinRevealStyle.ActionButton(
                        fontSize: 22,
                        minHeight: 62,
                        corners: .pill,
                        foreground: palette.background,
                        background: palette.accent,
                        border: nil,
                        shadow: .none
                    ),
                    reroll: SkinRevealStyle.ActionButton(
                        fontSize: 19,
                        minHeight: 56,
                        corners: .pill,
                        foreground: palette.primaryText,
                        // A bespoke shade with no palette match — distinct from both
                        // `background` (0x140F2E) and `surface` (0x241B52), used only here.
                        background: Color(hex: 0x180F38),
                        border: SkinBorder(color: palette.dashedBorder, width: 1.5),
                        shadow: .none
                    )
                ),
                confetti: SkinRevealStyle.ConfettiStyle(
                    motion: .falling,
                    colors: palette.flavors + [palette.surface],
                    cornerRadius: 2,
                    outline: nil
                )
            ),
            traits: SkinTraits(shakeToPick: true)
        )
    }()
}
