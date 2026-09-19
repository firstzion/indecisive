import Foundation

/// Every user-facing string that changes tone between skins (PLAN.md §4.3).
///
/// Plain Swift string interpolation for now, not yet a String Catalog with
/// real plural rules and localization — that's a bigger migration, still
/// deferred until the copy itself has settled further. Each closure does
/// its own simple singular/plural branching in the meantime.
struct SkinCopy: Sendable {
    // MARK: Home
    let homeSubtitle: @Sendable (_ listCount: Int) -> String
    let countLine: @Sendable (_ itemCount: Int) -> String
    let newListRow: String
    let homeFooter: @Sendable (_ totalPickCount: Int) -> String
    /// Shown in place of the list row(s) when there are no lists at all yet
    /// (a fresh install before onboarding seeds anything gets overridden by
    /// `SeedData`, but deleting every list afterward reaches this) — the
    /// Home-screen counterpart to `emptyStateTitle`/`emptyStateMessage`
    /// below, in the same per-skin voice.
    let homeEmptyStateTitle: String
    let homeEmptyStateMessage: String

    // MARK: List detail
    let detailHeadline: @Sendable (_ itemCount: Int) -> String
    let lastPickLine: @Sendable (_ itemName: String, _ date: Date) -> String
    let addRow: String
    let ctaCaption: String
    let ctaLabel: String
    /// Shown in place of the items card when a list has nothing in it yet
    /// (PLAN.md Phase 6: "Empty states per skin" — each skin's own voice,
    /// not one generic message reused everywhere).
    let emptyStateTitle: String
    let emptyStateMessage: String

    // MARK: Reveal
    let revealKicker: String
    /// A small label above the winner's name inside the name card (Gashapon's
    /// "YOU GOT"); `nil` for skins that just show the name. A defaulted `var`
    /// so a skin without one simply leaves it out of its initializer.
    var revealWinnerLabel: String? = nil
    let revealSupport: @Sendable (_ candidateCount: Int) -> String
    let acceptLabel: String
    let rerollLabel: String
}
