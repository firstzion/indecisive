import SwiftUI

/// Everything that changes between the app's three visual "skins": palette,
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
        case .gumball: return .gumball
        case .eightBall: return .eightBall
        case .prizeWheel: return .prizeWheel
        }
    }
}
