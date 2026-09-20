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

    /// The 8-Ball's "ASK. SHAKE. OBEY.": shaking the phone picks (on a list) and
    /// re-rolls (on the reveal) instead of tapping. The other skins ignore a
    /// shake. One decision, read by both `ListDetailView` and `RevealView` so the
    /// two can't disagree — and an exhaustive switch, so a new skin has to answer.
    var shakeToPick: Bool {
        switch id {
        case .eightBall: return true
        case .prizeWheel, .gashapon: return false
        }
    }
}
