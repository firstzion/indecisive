import SwiftUI

/// Every color a screen needs, named by what it's *for* rather than which
/// skin it belongs to — screens read `skin.palette.accent`, never a raw hex
/// value, so the same screen code renders correctly in all three skins.
struct SkinPalette: Sendable {
    /// The screen background (Home / Detail).
    let background: Color
    /// Card / list-row background.
    let surface: Color
    /// Card border color — `nil` means the card relies on shadow alone
    /// (Gumball has no card border at all).
    let surfaceBorder: Color?
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    let chevron: Color
    let divider: Color
    let dashedBorder: Color
    /// The one loud color: the "+", the Pick For Me button, etc.
    let accent: Color
    /// Text/icon color to place *on* `accent`.
    let onAccent: Color
    /// The per-list "flavour" colors — Gumball capsules, 8-Ball diamonds,
    /// Wheel wedges. Cycled by `PickList.flavorIndex`.
    let flavors: [Color]
    /// The reveal screen's own background (often the accent, sometimes not).
    let revealBackground: Color
    /// Whether Home/Detail read as a light or dark screen, for
    /// `.preferredColorScheme`. The reveal screen may pick its own scheme
    /// independently once its own background is known (Phase 3).
    let colorScheme: ColorScheme
}
