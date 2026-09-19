import SwiftUI

extension Skin {
    /// 1c — fairground stickers, hard black outlines, wedges everywhere.
    static let prizeWheel = Skin(
        id: .prizeWheel,
        name: "Prize Wheel",
        tagline: "Fairground stickers, hard black outlines, wedges everywhere.",
        palette: SkinPalette(
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
            flavors: [0xF0503C, 0xFFC93C, 0x1F9E8E, 0xFBF3E4].map { Color(hex: $0) },
            revealBackground: Color(hex: 0xFFC93C),
            colorScheme: .light
        ),
        type: SkinTypography(
            display: [
                .regular: "TitanOne", .medium: "TitanOne", .semibold: "TitanOne",
                .bold: "TitanOne", .extrabold: "TitanOne", .black: "TitanOne",
            ],
            body: [
                .regular: "WorkSans-Regular", .medium: "WorkSansRoman-Medium",
                .semibold: "WorkSansRoman-SemiBold", .bold: "WorkSansRoman-Bold",
                .extrabold: "WorkSansRoman-ExtraBold",
            ],
            mono: [.regular: "DMMono-Regular", .medium: "DMMono-Medium"]
        ),
        shape: SkinShape(
            cardRadius: 18,
            cardBorderWidth: 3,
            cardShadow: .hard(offset: CGSize(width: 4, height: 4), color: Color(hex: 0x17130F)),
            dashedBorderWidth: 3,
            dashedCornerRadius: 18,
            ctaHeight: 68,
            ctaCornerRadius: 20,
            ctaBorderWidth: 3,
            ctaShadow: .hard(offset: CGSize(width: 5, height: 5), color: Color(hex: 0x17130F))
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
        )
    )
}
