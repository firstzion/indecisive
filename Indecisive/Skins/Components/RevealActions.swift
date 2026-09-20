import SwiftUI

/// The accept / re-roll buttons below the reveal. Whether they stack as two
/// full-width pills (the 8-Ball, Gashapon) or sit side by side as blocks (the
/// Wheel) is the skin's own choice — `skin.reveal.actions`.
struct RevealActions: View {
    let skin: Skin
    /// Whether the winner is on screen yet — see
    /// `RevealView.actionsEnabled`. Both buttons are inert and visibly
    /// dimmed until it is, rather than silently swallowing taps.
    var isEnabled: Bool = true
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
            switch skin.reveal.actions.axis {
            case .vertical:
                VStack(spacing: 12) { accept; reroll }
            case .horizontal:
                HStack(spacing: 12) { accept; reroll }
            }
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.55)
        .animation(.easeOut(duration: 0.2), value: isEnabled)
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
            .font(skin.type.display(spec.fontSize, weight: .bold))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            // minHeight so a wrapped label at large Dynamic Type sizes has
            // room to grow instead of clipping (PLAN.md Phase 6).
            .frame(minHeight: spec.minHeight)
            .foregroundStyle(spec.foreground)
            .background(spec.background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                if let border = spec.border {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(border.color, lineWidth: border.width)
                }
            }
            .indShadow(spec.shadow, cornerRadius: cornerRadius)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }

    private var spec: SkinRevealStyle.ActionButton {
        switch role {
        case .accept: return skin.reveal.actions.accept
        case .reroll: return skin.reveal.actions.reroll
        }
    }

    private var cornerRadius: CGFloat {
        spec.corners.radius(forHeight: spec.minHeight)
    }

    // `foreground` and `background` are internal (not `private`) so
    // `ContrastTests` can check each button's label against its own fill
    // through the component itself.
    var foreground: Color { spec.foreground }
    var background: Color { spec.background }
}
