import SwiftUI

/// Everything that changes between the app's visual "skins": palette,
/// type, shape/shadow language and copy. Screens read only these semantic
/// tokens — never a raw hex value, PostScript name or hardcoded string — so
/// switching skins never requires touching a screen.
struct Skin: Identifiable, Sendable {
    let id: SkinID
    let name: String
    let tagline: String
    let palette: SkinPalette
    let type: SkinTypography
    let shape: SkinShape
    let copy: SkinCopy

    static func skin(for id: SkinID) -> Skin {
        switch id {
        case .eightBall: return .eightBall
        case .prizeWheel: return .prizeWheel
        case .gashapon: return .gashapon
        }
    }

    /// Every shipped skin, in `SkinID.allCases` order.
    ///
    /// Derived, never hand-listed: a new `SkinID` case shows up here on its
    /// own, so everything that iterates this — chiefly the tests (contrast,
    /// fonts, copy, snapshots) — covers a new skin without anyone remembering
    /// to add it to a literal, which is how a new skin used to slip past them.
    /// Iterate this, not `[Skin.eightBall, …]`.
    static let all: [Skin] = SkinID.allCases.map(Skin.skin(for:))
}
