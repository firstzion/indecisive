import SwiftUI

/// A hard-edged CSS-style *inset* shadow: a band of `color` hugging the inside
/// edge of `shape` on the side opposite the offset (`x`, `y`). Drawn as the
/// shape filled with `color`, minus a copy of the shape shifted by the offset.
///
/// There is deliberately no blur. The mockup's soft glows (`inset … 8px …`) are
/// built from gradients instead — see `CapsuleBall` — because SwiftUI's
/// `.blur` isn't drawn by the snapshot renderer, and a blurred, masked layer
/// per list row costs more than a gradient does.
struct InsetShadow<S: Shape>: View {
    let shape: S
    let color: Color
    var x: CGFloat = 0
    var y: CGFloat = 0

    var body: some View {
        shape
            .fill(color)
            .mask {
                shape
                    .overlay {
                        shape
                            .offset(x: x, y: y)
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()
            }
    }
}

/// The two paints of Gashapon's capsule art that have no slot in `SkinPalette`:
/// the cream lower half and the yellow prize ball. They belong to the capsule art
/// (`CapsuleBall`, `OpenCapsule`) and to `Gashapon.swift`, whose reveal reuses the
/// cream. No shared component names them — those read `skin.reveal` / `skin.palette`.
enum CapsulePaint {
    /// The pale lower half of every capsule.
    static let shell = Color(hex: 0xFFF7E8)
    /// The prize ball inside the opened capsule.
    static let prize = Color(hex: 0xFFD23D)
}

/// Gashapon's two-tone capsule seen from the side: a flavor-colored top half,
/// a thin seam and a cream bottom half, lit from the top left. Drawn at three
/// sizes — the Home badge (46), the detail hero (56) and the item-row marker
/// (18) — so every measurement scales from the design's 46pt badge.
struct CapsuleBall: View {
    /// The flavor color of the top half.
    let top: Color
    /// The capsule's ink — the seam between the halves is drawn in it.
    let ink: Color
    let size: CGFloat
    /// The seam is a hair lighter on the row markers than on the badges.
    var seamOpacity = 0.22
    /// The glossy rim light. The design leaves it off the row markers.
    var glossy = true

    var body: some View {
        let k = size / 46
        let seam = ink.opacity(seamOpacity)
        Circle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: top, location: 0),
                        .init(color: top, location: 0.47),
                        .init(color: seam, location: 0.47),
                        .init(color: seam, location: 0.53),
                        .init(color: CapsulePaint.shell, location: 0.53),
                        .init(color: CapsulePaint.shell, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                if glossy {
                    // The mockup's `inset 6px 7px 8px -6px rgba(255,255,255,.95)`.
                    // A blurred inset shadow glows brightest right at the rim
                    // (about 75% white) and fades over the next ~8pt, with a
                    // faint spill down the sides. A radial ramp whose centre is
                    // nudged (6, 7) toward the bottom-right reproduces that:
                    // the top-left rim sits furthest from the centre, so it is
                    // where the ramp is brightest.
                    Circle().fill(
                        RadialGradient(
                            stops: [
                                .init(color: .white.opacity(0), location: 0),
                                .init(color: .white.opacity(0.10), location: 0.30),
                                .init(color: .white.opacity(0.40), location: 0.62),
                                .init(color: .white.opacity(0.75), location: 0.94),
                                .init(color: .white.opacity(0.78), location: 1),
                            ],
                            center: UnitPoint(x: 0.5 + 6.0 / 46, y: 0.5 + 7.0 / 46),
                            startRadius: 20 * k,
                            endRadius: 33 * k
                        )
                    )
                }
            }
            .frame(width: size, height: size)
    }
}
