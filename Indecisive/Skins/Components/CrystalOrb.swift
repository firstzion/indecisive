import SwiftUI

/// The paints of Crystal Ball's art that have no slot in `SkinPalette`, and the tints its orbs
/// are drawn from. They belong to the art (`CrystalOrb`, `CrystalBallOnStand`, the stars) and to
/// `CrystalBall.swift`, which builds the palette's `accent` and `flavors` from them so the two
/// can't drift apart. The values are the mockup's own.
enum CrystalPaint {
    /// One list's colour: the bright glow at its orb's heart, and the deeper shade at its rim.
    struct Tint: Sendable {
        let light: Color
        let deep: Color
    }

    static let gold = Color(hex: 0xF3C969)
    static let pink = Color(hex: 0xFF8BD1)
    static let cyan = Color(hex: 0x8FE9FF)
    static let mint = Color(hex: 0xB7FFD8)
    /// The palest of the stars.
    static let starlight = Color(hex: 0xF7EDFF)

    /// The list orbs, in the order lists are given their colours (`PickList.flavorIndex`).
    static let tints: [Tint] = [
        Tint(light: pink, deep: Color(hex: 0x7B3FB0)),
        Tint(light: cyan, deep: Color(hex: 0x3A6FB0)),
        Tint(light: gold, deep: Color(hex: 0xA9701F)),
        Tint(light: mint, deep: Color(hex: 0x2F8F72)),
    ]

    /// The tint for a list's `flavorIndex`, wrapping round the palette.
    static func tint(forFlavorIndex index: Int) -> Tint {
        tints[((index % tints.count) + tints.count) % tints.count]
    }

    /// The dot beside each item in a list: gold, pink, cyan, and round again.
    static let markers: [Color] = [gold, pink, cyan]

    /// The bead on the Pick For Me button is one flat shade under its highlight.
    static let bead = Color(hex: 0x7B3FB0)

    /// The reveal ball, from its glowing heart out to its rim.
    static let ballMid = Color(hex: 0x6B2FA0)
    static let ballRim = Color(hex: 0x3B1663)
    /// The gold stand's base bar, a shade darker than the stand itself.
    static let standBar = Color(hex: 0xC79A37)
}

/// CSS's `radial-gradient(circle at cx% cy%, …)` over a `size` × `size` box, as SwiftUI draws it.
///
/// A CSS circle gradient with no explicit size runs out to the *farthest corner* of its box, and
/// its stops sit at fractions of that distance. SwiftUI's `endRadius` is the same idea, so this
/// works that distance out for the given centre and the mockup's stops carry over unchanged.
func cssRadialGradient(stops: [Gradient.Stop], centre: UnitPoint, in size: CGFloat) -> RadialGradient {
    let dx = max(centre.x, 1 - centre.x) * size
    let dy = max(centre.y, 1 - centre.y) * size
    return RadialGradient(stops: stops, center: centre, startRadius: 0, endRadius: (dx * dx + dy * dy).squareRoot())
}

/// A glossy little crystal orb: Home's list badge, the list-detail hero, and the bead on the Pick
/// For Me button. Each is the mockup's two stacked radial gradients — a soft white highlight up
/// and to the left, over a glow that shades from the list's colour to a deeper rim — and the
/// badges add a halo in the list's colour. The mockup draws them at 44, 58 and 26 points; every
/// measurement scales from those, so the orb keeps its look at the sizes the screens use.
struct CrystalOrb: View {
    enum Look {
        /// The Home row's badge, in a list's colour.
        case badge(CrystalPaint.Tint)
        /// The larger orb in the list-detail header, in a list's colour.
        case hero(CrystalPaint.Tint)
        /// The bead on the button: a bright highlight over one flat shade, and no halo.
        case bead
    }

    let look: Look
    let size: CGFloat

    /// What the mockup's measurements for this look were drawn against.
    private struct Spec {
        let designSize: CGFloat
        /// The highlight's peak opacity, and how far across the orb it reaches (a share of the
        /// gradient's radius).
        let highlightAlpha: Double
        let highlightReach: Double
        /// The list's colours and where its glow reaches the deep shade; `nil` for the bead.
        let tint: CrystalPaint.Tint?
        let deepReach: Double
        /// The halo's CSS blur radius.
        let haloBlur: CGFloat
    }

    private var spec: Spec {
        switch look {
        case let .badge(tint):
            return Spec(designSize: 44, highlightAlpha: 0.55, highlightReach: 0.48, tint: tint, deepReach: 0.70, haloBlur: 16)
        case let .hero(tint):
            return Spec(designSize: 58, highlightAlpha: 0.6, highlightReach: 0.48, tint: tint, deepReach: 0.72, haloBlur: 26)
        case .bead:
            return Spec(designSize: 26, highlightAlpha: 0.9, highlightReach: 0.52, tint: nil, deepReach: 0, haloBlur: 0)
        }
    }

    var body: some View {
        let spec = spec
        let k = size / spec.designSize
        Circle()
            .fill(base(spec))
            .overlay {
                Circle().fill(
                    cssRadialGradient(
                        stops: [
                            .init(color: .white.opacity(spec.highlightAlpha), location: 0),
                            .init(color: .white.opacity(0), location: spec.highlightReach),
                        ],
                        centre: UnitPoint(x: 0.34, y: 0.28),
                        in: size
                    )
                )
            }
            .frame(width: size, height: size)
            .background {
                if let tint = spec.tint {
                    // The mockup's `0 0 16px -4px` (badge) / `0 0 26px -4px` (hero) halo: the
                    // orb's own outline pulled in 4pt, then blurred. A SwiftUI shadow's radius
                    // is half a CSS blur radius.
                    Circle()
                        .fill(tint.light)
                        .padding(4 * k)
                        .shadow(color: tint.light.opacity(0.7), radius: spec.haloBlur / 2 * k)
                }
            }
    }

    /// The orb's body: light at the heart (a little below and to the right of centre), deep at the rim.
    private func base(_ spec: Spec) -> AnyShapeStyle {
        guard let tint = spec.tint else { return AnyShapeStyle(CrystalPaint.bead) }
        return AnyShapeStyle(
            cssRadialGradient(
                stops: [
                    .init(color: tint.light, location: 0),
                    .init(color: tint.deep, location: spec.deepReach),
                ],
                centre: UnitPoint(x: 0.6, y: 0.7),
                in: size
            )
        )
    }
}
