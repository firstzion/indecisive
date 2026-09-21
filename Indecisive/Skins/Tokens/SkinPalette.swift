import SwiftUI

/// Every color a screen needs, named by what it's *for* rather than which
/// skin it belongs to — screens read `skin.palette.accent`, never a raw hex
/// value, so the same screen code renders correctly in every skin.
struct SkinPalette: Sendable {
    /// The screen background (Home / Detail).
    let background: Color
    /// Card / list-row background.
    let surface: Color
    /// Card border color — `nil` means the card relies on shadow alone.
    let surfaceBorder: Color?
    let primaryText: Color
    /// The app's title at the top of Home. `primaryText` in every skin but one — Crystal
    /// Ball's mockup sets it in gold — so it is a role of its own rather than a reuse.
    let titleText: Color
    let secondaryText: Color
    let tertiaryText: Color
    let chevron: Color
    let divider: Color
    let dashedBorder: Color
    /// The one loud color: the "+", the Pick For Me button, etc.
    let accent: Color
    /// Text/icon color to place *on* `accent`.
    let onAccent: Color
    /// The accent used as *text* on `background` — the "‹ Lists" back button,
    /// "Edit"/"Done", and "Add".
    ///
    /// A role of its own, because `accent` is chosen as a **fill** (things sit
    /// on it; that is what `onAccent` is for) and a colour that reads well
    /// filled doesn't necessarily read well as 16pt type on the screen behind
    /// it. Gashapon's is the case in point: its accent measures 2.93:1 on its
    /// own background, under the 3:1 that large text needs, so every one of
    /// those three controls was failing AA. Deepening the accent itself would
    /// have repainted the CTA and the "+" button too.
    let accentText: Color
    /// Fill for destructive controls: the swipe-to-delete backdrop, and the
    /// edit-mode "minus" (which is drawn on `surface`, so it has to read there too).
    let destructive: Color
    /// Glyph color to place *on* `destructive`.
    let onDestructive: Color
    /// The per-list "flavour" colors — 8-Ball diamonds, Wheel wedges.
    /// Cycled by `PickList.flavorIndex`.
    let flavors: [Color]
    /// The reveal screen's own background (often the accent, sometimes not).
    let revealBackground: Color
    /// Whether Home/Detail read as a light or dark screen, for
    /// `.preferredColorScheme`. The reveal screen sets its own —
    /// `SkinRevealStyle.colorScheme` — since its background is often much louder.
    let colorScheme: ColorScheme
}
