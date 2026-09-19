import SwiftUI

extension Skin {
    /// 2a — capsule machine: chrome-white, two-tone capsules, crank the knob
    /// and see what drops.
    static let gashapon = Skin(
        id: .gashapon,
        name: "Gashapon",
        tagline: "Capsule machine, two-tone capsules, crank the knob and see what drops.",
        palette: SkinPalette(
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
            flavors: [0xFF5D8F, 0x21C7E8, 0x4BE0B0, 0xFFD23D, 0xFF9F4D].map { Color(hex: $0) },
            revealBackground: Color(hex: 0x21C7E8),
            colorScheme: .light
        ),
        type: SkinTypography(
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
            mono: [.regular: "DMMono-Regular", .medium: "DMMono-Medium"]
        ),
        shape: SkinShape(
            cardRadius: 24,
            cardBorderWidth: 0,
            cardShadow: .soft(radius: 6, x: 0, y: 4, color: Color(hex: 0x16283C), opacity: 0.14),
            dashedBorderWidth: 2.5,
            dashedCornerRadius: 24,
            ctaHeight: 68,
            ctaCornerRadius: 34,
            ctaBorderWidth: 0,
            ctaShadow: .soft(radius: 14, x: 0, y: 10, color: Color(hex: 0xFA578B), opacity: 0.6)
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
        )
    )
}

/// The few Gashapon paints that have no slot in `SkinPalette`: the capsule's
/// cream lower half, and the deep teal ink the reveal screen uses on its cyan
/// background (the rest of the skin uses navy). Kept in one place because
/// several components draw the same capsule.
enum GashaponPaint {
    /// The pale lower half of every capsule — also the reveal's name card and
    /// button fill.
    static let shell = Color(hex: 0xFFF7E8)
    /// Text and glyphs on the reveal's cyan background.
    static let revealInk = Color(hex: 0x0B3D4C)
    /// The prize ball inside the opened capsule, and a confetti color.
    static let coin = Color(hex: 0xFFD23D)
}
