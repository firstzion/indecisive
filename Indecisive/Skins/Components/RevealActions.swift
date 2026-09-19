import SwiftUI

/// The accept / re-roll buttons below the reveal. The 8-Ball stacks two
/// full-width pills; the Wheel places two side-by-side blocks instead — a
/// real layout difference, not just a color change.
struct RevealActions: View {
    let skin: Skin
    let onAccept: () -> Void
    let onReroll: () -> Void

    @State private var acceptTrigger = false
    @State private var rerollTrigger = false

    var body: some View {
        let accept = Button(skin.copy.acceptLabel) {
            acceptTrigger.toggle()
            onAccept()
        }
        .buttonStyle(RevealActionStyle(skin: skin, role: .accept))
        .accessibilityIdentifier("acceptButton")

        let reroll = Button {
            rerollTrigger.toggle()
            onReroll()
        } label: {
            HStack(spacing: 10) {
                RevealActionGlyph(skin: skin)
                Text(skin.copy.rerollLabel)
            }
        }
        .buttonStyle(RevealActionStyle(skin: skin, role: .reroll))
        .accessibilityIdentifier("rerollButton")

        Group {
            switch skin.id {
            case .eightBall:
                VStack(spacing: 12) { accept; reroll }
            case .prizeWheel:
                HStack(spacing: 12) { accept; reroll }
            }
        }
        .sensoryFeedback(.success, trigger: acceptTrigger)
        .sensoryFeedback(.impact(weight: .light), trigger: rerollTrigger)
    }
}

enum RevealActionRole { case accept, reroll }

struct RevealActionStyle: ButtonStyle {
    let skin: Skin
    let role: RevealActionRole

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(skin.type.display(fontSize, weight: .bold))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            // minHeight so a wrapped label at large Dynamic Type sizes has
            // room to grow instead of clipping (PLAN.md Phase 6).
            .frame(minHeight: height)
            .foregroundStyle(foreground)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                if borderWidth > 0 {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: borderWidth)
                }
            }
            .indShadow(shadow, cornerRadius: cornerRadius)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }

    private var fontSize: CGFloat {
        switch (skin.id, role) {
        case (.eightBall, .accept): return 22
        default: return 19
        }
    }

    private var height: CGFloat {
        switch skin.id {
        case .prizeWheel: return 60
        default: return role == .accept ? 62 : 56
        }
    }

    private var cornerRadius: CGFloat { skin.id == .prizeWheel ? 18 : height / 2 }

    private var foreground: Color {
        switch (skin.id, role) {
        case (.eightBall, .accept): return skin.palette.background
        case (.eightBall, .reroll): return skin.palette.primaryText
        case (.prizeWheel, .accept): return skin.palette.background
        case (.prizeWheel, .reroll): return skin.palette.primaryText
        }
    }

    private var background: Color {
        switch (skin.id, role) {
        case (.eightBall, .accept): return skin.palette.accent
        // A bespoke shade with no existing token match — distinct from
        // both `background` (0x140F2E) and `surface` (0x241B52), used
        // only here.
        case (.eightBall, .reroll): return Color(hex: 0x180F38)
        // Also bespoke — coincides with `palette.flavors[2]`, but "the
        // accept button's color" isn't really "flavour #3", so this keeps
        // its own literal rather than reading that array.
        case (.prizeWheel, .accept): return Color(hex: 0x1F9E8E)
        case (.prizeWheel, .reroll): return skin.palette.background
        }
    }

    private var borderWidth: CGFloat {
        switch (skin.id, role) {
        case (.eightBall, .reroll): return 1.5
        case (.prizeWheel, _): return 3
        default: return 0
        }
    }

    private var borderColor: Color {
        switch skin.id {
        case .eightBall: return skin.palette.dashedBorder
        case .prizeWheel: return skin.palette.primaryText
        }
    }

    private var shadow: SkinShadowStyle {
        switch (skin.id, role) {
        case (.prizeWheel, _): return .hard(offset: CGSize(width: 4, height: 4), color: skin.palette.primaryText)
        default: return .none
        }
    }
}

/// The little wiggling glyph next to the 8-Ball's "SHAKE AGAIN". The
/// Wheel's "SPIN AGAIN" has no glyph in the source design.
struct RevealActionGlyph: View {
    let skin: Skin
    @State private var wiggle = false
    @Environment(\.indReducedMotion) private var reduceMotion

    var body: some View {
        Group {
            switch skin.id {
            case .eightBall:
                // Standalone decorative accent — coincides with
                // `palette.flavors[0]`, but this glyph isn't showing "a
                // flavour".
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: 0xFF4FD8))
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(45))
            case .prizeWheel:
                EmptyView()
            }
        }
        .rotationEffect(.degrees(wiggle ? 4 : -4))
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                wiggle = true
            }
        }
    }
}
