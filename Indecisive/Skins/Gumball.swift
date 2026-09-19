import SwiftUI

extension Skin {
    /// 1a — cream ground, candy capsules, every list gets its own flavour.
    static let gumball = Skin(
        id: .gumball,
        name: "Gumball",
        tagline: "Cream ground, candy capsules, every list gets its own flavour.",
        palette: SkinPalette(
            background: Color(hex: 0xFFF8EC),
            surface: Color(hex: 0xFFFFFF),
            surfaceBorder: nil,
            primaryText: Color(hex: 0x2B1B12),
            secondaryText: Color(hex: 0x7E6553),
            // Darkened from the design's #8E7460 (4.13:1 on #FFF8EC, fails
            // WCAG AA's 4.5:1 for normal text) — PLAN.md §4.4 flagged this
            // exact pair as a known risk spot.
            tertiaryText: Color(hex: 0x7E6551),
            // Darkened from the design's #D6C4B4 (1.69:1 on the card
            // surface #FFFFFF, fails WCAG AA's 3:1 for a UI component) —
            // this renders the "›" list-row indicator and the item-reorder
            // arrows, both read against `surface`, never `background`.
            chevron: Color(hex: 0xAD8969),
            divider: Color(hex: 0xF4EBE0),
            dashedBorder: Color(hex: 0xE3D2C0),
            accent: Color(hex: 0xFF3B5C),
            onAccent: .white,
            flavors: [0xFF3B5C, 0x7B5CFF, 0x35D6A6, 0xFF7AB8, 0xFFB020].map { Color(hex: $0) },
            revealBackground: Color(hex: 0xFF3B5C),
            colorScheme: .light
        ),
        type: SkinTypography(
            display: [
                .regular: "Baloo2-Regular", .medium: "Baloo2-Medium", .semibold: "Baloo2-SemiBold",
                .bold: "Baloo2-Bold", .extrabold: "Baloo2-ExtraBold",
            ],
            body: [
                .regular: "Nunito-Regular", .medium: "Nunito-Medium", .semibold: "Nunito-SemiBold",
                .bold: "Nunito-Bold", .extrabold: "Nunito-ExtraBold", .black: "Nunito-Black",
            ],
            mono: [.regular: "DMMono-Regular", .medium: "DMMono-Medium"]
        ),
        shape: SkinShape(
            cardRadius: 22,
            cardBorderWidth: 0,
            cardShadow: .soft(radius: 0, x: 0, y: 3, color: Color(hex: 0x2B1B12), opacity: 0.06),
            dashedBorderWidth: 2.5,
            dashedCornerRadius: 22,
            ctaHeight: 66,
            ctaCornerRadius: 33,
            ctaBorderWidth: 0,
            ctaShadow: .soft(radius: 24, x: 0, y: 10, color: Color(hex: 0xFF3B5C), opacity: 0.75)
        ),
        copy: SkinCopy(
            homeSubtitle: { n in "\(n) list\(n == 1 ? "" : "s") · infinite indecision" },
            countLine: { n in "\(n) thing\(n == 1 ? "" : "s")" },
            newListRow: "New list",
            homeFooter: { _ in "Can't decide? That's the whole point." },
            homeEmptyStateTitle: "No lists yet",
            homeEmptyStateMessage: "Tap below to start your first one.",
            detailHeadline: { n in "\(n) thing\(n == 1 ? "" : "s") to choose from" },
            lastPickLine: { name, date in
                "Last pick: \(name), \(date.formatted(.dateTime.weekday(.wide)))"
            },
            addRow: "Add something new",
            ctaCaption: "Let fate decide",
            ctaLabel: "Pick For Me",
            emptyStateTitle: "Nothing here yet",
            emptyStateMessage: "Add a few flavours before you can pick.",
            revealKicker: "AND THE WINNER IS…",
            revealSupport: { n in "Chosen out of \(n). No takebacks." },
            acceptLabel: "Sold, let's go",
            rerollLabel: "Nope, roll again"
        )
    )
}
