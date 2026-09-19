import SwiftUI

extension Skin {
    /// 1b — dark arcade cabinet, neon answers, the ball does the talking.
    static let eightBall = Skin(
        id: .eightBall,
        name: "Midnight 8-Ball",
        tagline: "Dark arcade cabinet, neon answers, the ball does the talking.",
        palette: SkinPalette(
            background: Color(hex: 0x140F2E),
            surface: Color(hex: 0x241B52),
            surfaceBorder: Color(hex: 0x362A72),
            primaryText: Color(hex: 0xF2EEFF),
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
            flavors: [0xFF4FD8, 0x4DE1FF, 0xC8FF4D].map { Color(hex: $0) },
            revealBackground: Color(hex: 0x0B0818),
            colorScheme: .dark
        ),
        type: SkinTypography(
            display: [
                .regular: "LilitaOne", .medium: "LilitaOne", .semibold: "LilitaOne",
                .bold: "LilitaOne", .extrabold: "LilitaOne", .black: "LilitaOne",
            ],
            body: [
                .regular: "SpaceGrotesk-Light_Regular", .medium: "SpaceGrotesk-Light_Medium",
                .semibold: "SpaceGrotesk-Light_Medium", .bold: "SpaceGrotesk-Light_Bold",
            ],
            mono: [.regular: "DMMono-Regular", .medium: "DMMono-Medium"]
        ),
        shape: SkinShape(
            cardRadius: 20,
            cardBorderWidth: 1,
            cardShadow: .none,
            dashedBorderWidth: 2,
            dashedCornerRadius: 20,
            ctaHeight: 68,
            ctaCornerRadius: 34,
            ctaBorderWidth: 0,
            ctaShadow: .glow(color: Color(hex: 0xC8FF4D), radius: 24, opacity: 0.5)
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
        )
    )
}
