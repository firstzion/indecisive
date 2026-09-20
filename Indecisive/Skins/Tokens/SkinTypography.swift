import SwiftUI

/// Semantic font weights a screen can ask for. Not every skin's font ships
/// every weight — `SkinTypography` maps each one to the closest weight the
/// face actually has, so a screen can ask for `.semibold` even on a skin
/// whose body font has no semibold instance.
enum SkinFontWeight: Hashable, CaseIterable {
    case regular, medium, semibold, bold, extrabold, black
}

/// The three type roles a screen uses: `display` for headlines, hero
/// numbers and button labels; `body` for everything else; and `mono` for
/// the 8-Ball's list indices. Every lookup goes through
/// `Font.custom(_:size:relativeTo:)` so Dynamic Type still scales even
/// though the underlying face is fixed per skin.
///
/// PostScript names below are **not** guessed from each font file's tables —
/// several (Space Grotesk, Work Sans) have surprising real names that only
/// showed up by actually querying `UIFont.fontNames` on-device. See
/// `FontRegistry.swift`, which is the source of truth these were copied from.
struct SkinTypography: Sendable {
    private let displayNames: [SkinFontWeight: String]
    private let bodyNames: [SkinFontWeight: String]
    private let monoNames: [SkinFontWeight: String]
    /// Which of the three faces `compactTitle(_:weight:)` uses.
    let compactTitleRole: Role

    init(
        display: [SkinFontWeight: String],
        body: [SkinFontWeight: String],
        mono: [SkinFontWeight: String],
        compactTitle: Role
    ) {
        self.displayNames = display
        self.bodyNames = body
        self.monoNames = mono
        self.compactTitleRole = compactTitle
    }

    /// The three type roles, exposed so tests can enumerate every
    /// PostScript name a skin's typography table can actually produce
    /// without needing to parse `Font`'s opaque debug description.
    enum Role { case display, body, mono }

    func display(_ size: CGFloat, weight: SkinFontWeight = .bold, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        .custom(name(for: .display, weight: weight), size: size, relativeTo: style)
    }

    func body(_ size: CGFloat, weight: SkinFontWeight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(name(for: .body, weight: weight), size: size, relativeTo: style)
    }

    func mono(_ size: CGFloat, weight: SkinFontWeight = .regular, relativeTo style: Font.TextStyle = .caption) -> Font {
        .custom(name(for: .mono, weight: weight), size: size, relativeTo: style)
    }

    /// Font for compact, dense titles — Home row names, dashed add-row labels — in
    /// whichever face the skin picked with `compactTitleRole`. A skin's display face
    /// isn't always the right one at this density (the Wheel's Titan One reads too
    /// heavy), so it can drop to its body face here while headlines and buttons keep
    /// the display one.
    func compactTitle(_ size: CGFloat, weight: SkinFontWeight = .bold) -> Font {
        switch compactTitleRole {
        case .display: return display(size, weight: weight, relativeTo: .body)
        case .body: return body(size, weight: weight, relativeTo: .body)
        case .mono: return mono(size, weight: weight, relativeTo: .body)
        }
    }

    /// Resolves a role + weight to the actual PostScript name that will be
    /// requested. Falls back to `.regular`, then to whatever's available,
    /// rather than silently dropping to the system font — a missing weight
    /// should be visibly wrong in a screenshot, not invisibly wrong.
    func name(for role: Role, weight: SkinFontWeight) -> String {
        // Every custom font in the app is requested through here, which makes
        // this the one place that can guarantee the files are registered
        // before anyone asks for them by name. It matters for a test bundle,
        // which links this framework but never launches the app and so never
        // reaches `IndecisiveApp.init()`. Idempotent and effectively free
        // after the first call — see `FontRegistry.ensureRegistered()`.
        FontRegistry.ensureRegistered()

        let table: [SkinFontWeight: String]
        switch role {
        case .display: table = displayNames
        case .body: table = bodyNames
        case .mono: table = monoNames
        }
        if let exact = table[weight] { return exact }
        if let regular = table[.regular] { return regular }
        // No exact match and no `.regular` either. Every table any shipped
        // skin actually passes to `init` defines every weight it uses, so
        // this only matters for a malformed future skin — but it used to
        // fall back to `table.values.first`, which is dictionary iteration
        // order: not guaranteed stable across launches (Swift's hashing is
        // randomized per process), so a skin missing `.regular` could
        // silently render a different face from run to run. Iterating
        // `SkinFontWeight`'s own declared case order instead makes the
        // choice deterministic — and prefer-closest-to-regular, since the
        // cases are declared in that order.
        for candidate in SkinFontWeight.allCases {
            if let name = table[candidate] { return name }
        }
        // The table for this role is completely empty. `"System"` used to
        // be returned here, but that isn't a real PostScript name either —
        // `Font.custom("System", …)` would just silently resolve to the
        // actual system font, exactly the invisible failure this whole
        // fallback chain exists to avoid. Fail loudly in DEBUG instead;
        // release builds still get a (clearly-fake, greppable) name rather
        // than crashing outright.
        assertionFailure("SkinTypography: no font at all defined for role \(role) — every role needs at least one weight.")
        return "Indecisive-NoFontConfigured"
    }
}
