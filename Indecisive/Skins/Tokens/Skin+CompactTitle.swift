import SwiftUI

extension Skin {
    /// Font for compact, dense titles — Home row titles, dashed add-row
    /// labels. The 8-Ball uses its display font even here; the Wheel's
    /// Titan One reads too heavy at this density, so it drops to
    /// its body font instead. This matches the source design exactly: the
    /// Wheel's home-row list names and dashed rows are Work Sans, while its
    /// big detail headline and CTA are still Titan One.
    func compactTitleFont(_ size: CGFloat, weight: SkinFontWeight = .bold) -> Font {
        switch id {
        case .eightBall: return type.display(size, weight: weight, relativeTo: .body)
        case .prizeWheel: return type.body(size, weight: weight, relativeTo: .body)
        }
    }
}
