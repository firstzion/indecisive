import SwiftUI

/// Gashapon's reveal centrepiece: a capsule whose top half pops off to show a
/// yellow prize ball. Laid out at the mockup's 200×238; `lidOpen` lifts and
/// tilts the lid (the mockup's `pfm-lid`). The caller animates `lidOpen`, so
/// the same view is the closed capsule, the open one, or anything between.
struct OpenCapsule: View {
    let skin: Skin
    let lidOpen: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Painted in the mockup's order: lid, then the lower half over the
            // lid's bottom edge, then the prize ball over both.
            lid
                .frame(width: 176, height: 88)
                .rotationEffect(.degrees(lidOpen ? -22 : 0))
                .offset(x: 12, y: lidOpen ? 64 - 46 : 64)
            shell
                .frame(width: 176, height: 92)
                .offset(x: 12, y: 146)
            prize
                .frame(width: 60, height: 60)
                .offset(x: 70, y: 126)
        }
        .frame(width: 200, height: 238, alignment: .topLeading)
    }

    /// The dome: a half-disc with a slightly squared-off bottom edge.
    private var lid: some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: 88, bottomLeadingRadius: 8,
            bottomTrailingRadius: 8, topTrailingRadius: 88,
            style: .continuous
        )
        return
            shape
            .fill(skin.palette.accent)
            .overlay {
                // The mockup's `inset 10px 12px 12px -8px rgba(255,255,255,.85)`
                // as a radial ramp (see `CapsuleBall`): centred (10, 12) toward
                // the bottom-right of the dome's circle, so its bright end lands
                // on the top-left rim.
                shape.fill(
                    RadialGradient(
                        stops: [
                            .init(color: .white.opacity(0), location: 0),
                            .init(color: .white.opacity(0.02), location: 0.07),
                            .init(color: .white.opacity(0.07), location: 0.25),
                            .init(color: .white.opacity(0.20), location: 0.44),
                            .init(color: .white.opacity(0.40), location: 0.62),
                            .init(color: .white.opacity(0.62), location: 0.80),
                            .init(color: .white.opacity(0.76), location: 0.98),
                        ],
                        center: UnitPoint(x: 98.0 / 176, y: 100.0 / 88),
                        startRadius: 82,
                        endRadius: 104
                    )
                )
            }
    }

    /// The bowl: shaded along its bottom inner edge.
    private var shell: some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: 8, bottomLeadingRadius: 88,
            bottomTrailingRadius: 88, topTrailingRadius: 8,
            style: .continuous
        )
        return
            shape
            .fill(CapsulePaint.shell)
            .overlay {
                // The mockup's faint `inset 0 -10px 14px -10px` shade: a soft
                // darkening along the bowl's bottom edge, about 17% at the rim.
                shape.fill(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.86),
                            .init(color: skin.palette.primaryText.opacity(0.18), location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
    }

    private var prize: some View {
        Circle()
            .fill(CapsulePaint.prize)
            .overlay {
                Text("!")
                    .font(skin.type.display(22))
                    .foregroundStyle(skin.palette.primaryText)
            }
            .shadow(color: skin.palette.primaryText.opacity(0.4), radius: 6, x: 0, y: 8)
    }
}
