import SwiftUI

/// The big "Pick For Me" button. The 8-Ball gets a colored glow, the Wheel a
/// thick ink border with a hard offset "sticker" shadow, and Gashapon a soft
/// pink shadow with a darker lip along its bottom edge.
struct PrimaryCTAStyle: ButtonStyle {
    let skin: Skin

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            PrimaryCTAGlyph(skin: skin)
            configuration.label
                .font(skin.type.display(22, weight: .extrabold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .foregroundStyle(skin.palette.onAccent)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        // minHeight, not a fixed height: at the largest Dynamic Type sizes
        // the label needs more room than the design's base height allows
        // (PLAN.md Phase 6: "the CTA grows").
        .frame(minHeight: skin.shape.ctaHeight)
        .background(skin.palette.accent)
        .overlay {
            // Gashapon's pill has a darker lip along its bottom edge (the
            // mockup's `inset 0 -4px 0 rgba(0,0,0,.12)`).
            if skin.id == .gashapon {
                InsetShadow(
                    shape: RoundedRectangle(cornerRadius: skin.shape.ctaCornerRadius, style: .continuous),
                    color: .black.opacity(0.12), y: -4
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: skin.shape.ctaCornerRadius, style: .continuous))
        .overlay {
            if skin.shape.ctaBorderWidth > 0 {
                RoundedRectangle(cornerRadius: skin.shape.ctaCornerRadius, style: .continuous)
                    .strokeBorder(skin.palette.primaryText, lineWidth: skin.shape.ctaBorderWidth)
            }
        }
        .indShadow(skin.shape.ctaShadow, cornerRadius: skin.shape.ctaCornerRadius)
        .opacity(configuration.isPressed ? 0.85 : 1)
        .scaleEffect(configuration.isPressed ? 0.98 : 1)
        .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// The little glyph inside the CTA: a mini 8-ball, a spinning wedge or a
/// turning capsule-machine knob — a tiny preview of "the toy" living right on
/// the button that triggers it.
struct PrimaryCTAGlyph: View {
    let skin: Skin
    var size: CGFloat = 26

    @State private var spinAngle = 0.0
    @Environment(\.indReducedMotion) private var reduceMotion

    var body: some View {
        Group {
            switch skin.id {
            case .eightBall:
                Circle()
                    // The 8-ball's own shell black — same paint as
                    // `revealBackground` (see also `ListBadge`, `HeroBadge`,
                    // `RevealCentrepiece`), not a one-off.
                    .fill(skin.palette.revealBackground)
                    .overlay {
                        Text("8")
                            .font(skin.type.display(size * 0.5))
                            .foregroundStyle(skin.palette.accent)
                    }

            case .prizeWheel:
                // The mini wheel's two wedge colors are the Wheel's own
                // reveal-background yellow and background cream — the same
                // two loudest colors the real reveal screen uses.
                WheelFill(wedgeCount: 4, colors: [skin.palette.revealBackground, skin.palette.background])
                    .overlay { Circle().strokeBorder(skin.palette.primaryText, lineWidth: 2.5) }
                    .rotationEffect(.degrees(spinAngle))
                    .onAppear {
                        guard !reduceMotion else { return }
                        withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) {
                            spinAngle = 360
                        }
                    }

            case .gashapon:
                // The machine's knob: a cream disc with a slot-shaped bar,
                // turning once every 3s like the mockup's.
                Circle()
                    .fill(GashaponPaint.shell)
                    .overlay {
                        RoundedRectangle(cornerRadius: size * 0.07, style: .continuous)
                            .fill(skin.palette.accent)
                            .frame(width: size * 0.57, height: size * 0.14)
                    }
                    .rotationEffect(.degrees(spinAngle))
                    .onAppear {
                        guard !reduceMotion else { return }
                        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                            spinAngle = 360
                        }
                    }
            }
        }
        .frame(width: size, height: size)
    }
}
