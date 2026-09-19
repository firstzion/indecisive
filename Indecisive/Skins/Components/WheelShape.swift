import SwiftUI

/// A conic "prize wheel" fill: `wedgeCount` equal hard-edged wedges cycling
/// through `colors`, matching the CSS `conic-gradient` hard-stop look in
/// the design exactly (each color repeats at both edges of its wedge, so
/// there's no blend between wedges). Used by the Prize Wheel skin's list
/// badge, hero badge and reveal centrepiece.
struct WheelFill: View {
    let wedgeCount: Int
    let colors: [Color]

    var body: some View {
        Circle().fill(gradient)
    }

    private var gradient: AngularGradient {
        guard wedgeCount > 0, !colors.isEmpty else {
            return AngularGradient(colors: [.gray], center: .center)
        }
        var stops: [Gradient.Stop] = []
        let step = 1.0 / Double(wedgeCount)
        for i in 0..<wedgeCount {
            let color = colors[i % colors.count]
            stops.append(.init(color: color, location: Double(i) * step))
            stops.append(.init(color: color, location: Double(i + 1) * step))
        }
        return AngularGradient(gradient: Gradient(stops: stops), center: .center, angle: .degrees(-90))
    }
}

/// Number of wedges to draw for a list with `itemCount` items — capped so
/// the wheel stays legible at small sizes (see PLAN.md Phase 4).
func wheelWedgeCount(forItemCount itemCount: Int) -> Int {
    max(min(itemCount, 8), 1)
}

/// The rotation (in degrees, including `extraSpins` full turns for a
/// satisfying spin-up) that brings wedge `winnerIndex`'s center to the top,
/// under the fixed pointer.
///
/// This has to match `WheelFill`'s own layout convention exactly: wedge
/// `i`'s center sits at `(i + 0.5) * wedgeAngle` degrees clockwise from the
/// top before any rotation, and `.rotationEffect` also turns clockwise for
/// positive degrees — so solving `wedgeCenter + rotation ≡ 0 (mod 360)` for
/// `rotation` gives the formula below. `winnerIndex` is taken mod
/// `wedgeCount` so a winner whose position in the list is beyond the
/// (capped-at-8) wedge count still lands on a valid wedge rather than
/// going out of bounds.
func wheelTargetSpinAngle(wedgeCount: Int, winnerIndex: Int, extraSpins: Int = 4) -> Double {
    guard wedgeCount > 0 else { return Double(extraSpins) * 360 }
    let wedgeAngle = 360.0 / Double(wedgeCount)
    let normalizedIndex = ((winnerIndex % wedgeCount) + wedgeCount) % wedgeCount
    let wedgeCenter = (Double(normalizedIndex) + 0.5) * wedgeAngle
    return -wedgeCenter + Double(extraSpins) * 360
}
