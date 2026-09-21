import SwiftUI

/// The reveal screen's visual centerpiece: the shape (8-ball / wheel /
/// capsule / crystal ball) plus the winner's name. For the Wheel and Gashapon,
/// the name sits in its own card below the shape; for the 8-Ball and Crystal
/// Ball, it appears inside the ball instead, so there's no separate name card
/// — a real structural difference in the source design, not just a color swap.
/// (Those two set their support line under the ball instead, straight onto
/// the background: `SkinRevealStyle.supportLine`.)
///
/// Each skin's intro animation is its own "toy" moment (PLAN.md §4.4):
/// the 8-Ball's ball wobbles for ~1.1s before the answer fades in; the
/// Wheel actually spins to the winner's wedge before its name card
/// appears; Gashapon's capsule pops in and its lid springs off; Crystal
/// Ball's pops in with its answer hidden, and the mist parts to show it. Re-created
/// fresh on every re-roll by the caller's `.id(model.rerollToken)`, so the
/// whole intro replays each time — including when a reroll lands back on
/// the same winner.
struct RevealCentrepiece: View {
    let skin: Skin
    let winnerName: String
    let candidateCount: Int
    /// Only meaningful for the Prize Wheel — which wedge (of `wedgeCount`)
    /// represents this winner, so the wheel can spin to it.
    let winnerWedgeIndex: Int
    let wedgeCount: Int

    @State private var popped = false
    @State private var spinAngle = 0.0
    @State private var wobbleAngle = 0.0
    @State private var resultRevealed = false
    /// Gashapon only: whether the capsule's lid has popped off yet.
    @State private var lidOpen = false
    @Environment(\.indReducedMotion) private var reduceMotion
    /// Plays the skin's haptic beats (`playHaptics()`), reusing one generator per kind.
    @State private var haptics = HapticPlayer()

    /// Every not-yet-fired delayed haptic/animation step scheduled by
    /// `startIntroAnimation()`, tracked so `cancelScheduledWork()` can
    /// stop them. Without this, dismissing the reveal mid-animation left
    /// every pending haptic (and the Wheel/8-Ball's delayed state
    /// mutations) scheduled and still firing on a screen no longer on
    /// screen.
    @State private var scheduledWork: [DispatchWorkItem] = []

    var body: some View {
        VStack(spacing: 22) {
            entranceWrappedShape

            if let card = skin.reveal.nameCard {
                let visible = nameCardVisible(card)
                nameCard(card)
                    .scaleEffect(visible ? 1 : 0.9)
                    .opacity(visible ? 1 : 0)
            } else if let support = skin.reveal.supportLine {
                supportLine(support)
            }
        }
        .onAppear(perform: startIntroAnimation)
        .onDisappear(perform: cancelScheduledWork)
    }

    /// The support line of a skin with no name card to hold it, set on the reveal background.
    /// It arrives with the answer, so the two read together — `resultRevealed` is the flag every
    /// intro that hides the answer (`.wobble`, `.spin`, `.mistParts`) sets when it shows.
    private func supportLine(_ support: SkinRevealStyle.SupportLine) -> some View {
        Text(skin.copy.revealSupport(candidateCount))
            .font(support.font)
            .foregroundStyle(support.color)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 26)
            .opacity(resultRevealed ? 1 : 0)
    }

    /// Whether the winner's name card should be showing yet — the Wheel
    /// deliberately holds it back until its spin finishes; Gashapon's pops in
    /// with the capsule.
    private func nameCardVisible(_ card: SkinRevealStyle.NameCard) -> Bool {
        switch card.appearance {
        case .withCentrepiece: return popped
        case .afterIntro: return resultRevealed
        }
    }

    @ViewBuilder
    private var entranceWrappedShape: some View {
        switch skin.motion.revealIntro {
        case .wobble, .popAndOpen, .mistParts:
            shape
                .scaleEffect(popped ? 1 : 0.72)
                .rotationEffect(.degrees((popped ? 0 : -6) + wobbleAngle))
                .opacity(popped ? 1 : 0)
        case .spin:
            // No bounce/scale here — that would fight visually with the
            // spin. Just a quick fade-in; the spin itself is the entrance.
            shape.opacity(popped ? 1 : 0)
        }
    }

    @ViewBuilder
    private var shape: some View {
        switch skin.id {
        case .eightBall:
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.28), skin.palette.background],
                            center: UnitPoint(x: 0.32, y: 0.26),
                            startRadius: 0,
                            endRadius: 125
                        )
                    )
                    .overlay(Circle().strokeBorder(skin.palette.surfaceBorder ?? .clear, lineWidth: 1))
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(skin.palette.revealBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(skin.palette.accent, lineWidth: 2)
                    )
                    .frame(width: 168, height: 168)
                    .rotationEffect(.degrees(45))
                    .overlay {
                        Text(winnerName.uppercased())
                            .font(skin.type.display(30))
                            .foregroundStyle(skin.palette.accent)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.5)
                            .lineLimit(3)
                            .frame(width: 148)
                            .opacity(resultRevealed ? 1 : 0)
                    }
            }
            .frame(width: 250, height: 250)

        case .prizeWheel:
            ZStack {
                WheelFill(wedgeCount: wedgeCount, colors: skin.palette.flavors)
                    .overlay(Circle().strokeBorder(skin.palette.primaryText, lineWidth: 4))
                    .rotationEffect(.degrees(spinAngle))
                Circle()
                    .fill(skin.palette.revealBackground)
                    .overlay(Circle().strokeBorder(skin.palette.primaryText, lineWidth: 4))
                    .frame(width: 92, height: 92)
                    .overlay {
                        Text("!").font(skin.type.display(30)).foregroundStyle(skin.palette.primaryText)
                    }
                Triangle()
                    .fill(skin.palette.primaryText)
                    .frame(width: 26, height: 24)
                    // Lowered so the tip actually overlaps the wheel's rim
                    // (a real peg would sit against it, not float above)
                    // instead of just floating clear of it.
                    .offset(y: -104)
            }
            .frame(width: 212, height: 212)

        case .gashapon:
            OpenCapsule(skin: skin, lidOpen: lidOpen)

        case .crystalBall:
            CrystalBallOnStand(skin: skin, winnerName: winnerName, nameVisible: resultRevealed)
        }
    }

    @ViewBuilder
    private func nameCard(_ card: SkinRevealStyle.NameCard) -> some View {
        VStack(spacing: 8) {
            if let label = skin.copy.revealWinnerLabel {
                Text(label)
                    .font(skin.type.display(13))
                    .tracking(2)
                    .foregroundStyle(card.labelColor)
            }
            Text(winnerName)
                .font(skin.type.display(34))
                .foregroundStyle(skin.palette.primaryText)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .lineLimit(2)
            Text(skin.copy.revealSupport(candidateCount))
                .font(skin.type.body(13, weight: .semibold))
                .foregroundStyle(skin.palette.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity)
        .background(card.fill)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            if let border = card.border {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(border.color, lineWidth: border.width)
            }
        }
        .indShadow(card.shadow, cornerRadius: 28)
        .padding(.horizontal, card.horizontalInset)
    }

    // MARK: Intro animations
    //
    // Each skin plays its own haptic pattern alongside its intro animation
    // (PLAN.md Phase 6: "Haptics per skin"), and each collapses to a near-
    // instant, motion-free reveal under Reduce Motion — the long Wheel spin
    // in particular is exactly the kind of animation Reduce Motion exists
    // to skip, not just slow down or soften.
    //
    // Every timing here, and the haptic pattern, is the skin's own
    // (`skin.motion`). `RevealView` announces the winner to VoiceOver from the
    // same numbers, so the two can't drift apart.

    private func startIntroAnimation() {
        cancelScheduledWork()  // defensive — see `scheduledWork`'s doc comment

        switch skin.motion.revealIntro {
        case let .wobble(swings, swingDuration, answerFadeIn):
            // `repeatCount(swings, autoreverses: true)` below takes `swings` full
            // back-and-forth cycles × `swingDuration` × 2 to run its course.
            let wobbleDuration = Double(swings) * 2 * swingDuration
            if reduceMotion {
                popped = true
                resultRevealed = true
            } else {
                withAnimation(.interpolatingSpring(stiffness: 170, damping: 14)) {
                    popped = true
                }
                withAnimation(.easeInOut(duration: swingDuration).repeatCount(swings, autoreverses: true)) {
                    wobbleAngle = 7
                }
                // Wait for the wobble to finish naturally instead of
                // cutting it off mid-swing — this used to force
                // `wobbleAngle` back to 0 at a fixed 0.6s, well before the
                // 1.08s the animation above actually takes, producing a
                // visible snap. It already ends back at 0 on its own (`swings`
                // is a whole number of round trips), so this assignment is
                // now just a harmless no-op safety net.
                afterDelay(wobbleDuration) {
                    wobbleAngle = 0
                    withAnimation(.easeIn(duration: answerFadeIn)) {
                        resultRevealed = true
                    }
                }
            }

        case let .spin(duration, turns, _):
            let target = wheelTargetSpinAngle(
                wedgeCount: wedgeCount, winnerIndex: winnerWedgeIndex,
                extraSpins: reduceMotion ? 0 : turns
            )
            if reduceMotion {
                popped = true
                spinAngle = target
                resultRevealed = true
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    popped = true
                }
                withAnimation(.timingCurve(0.15, 0.85, 0.25, 1, duration: duration)) {
                    spinAngle = target
                }
                afterDelay(duration) {
                    withAnimation(.interpolatingSpring(stiffness: 170, damping: 14)) {
                        resultRevealed = true
                    }
                }
            }

        case let .popAndOpen(lidDelay, _):
            if reduceMotion {
                popped = true
                lidOpen = true
            } else {
                withAnimation(.interpolatingSpring(stiffness: 170, damping: 14)) {
                    popped = true
                }
                afterDelay(lidDelay) {
                    withAnimation(.interpolatingSpring(stiffness: 190, damping: 12)) {
                        lidOpen = true
                    }
                }
            }

        case let .mistParts(partDelay, nameFadeIn):
            if reduceMotion {
                popped = true
                resultRevealed = true
            } else {
                withAnimation(.interpolatingSpring(stiffness: 170, damping: 14)) {
                    popped = true
                }
                // The ball is up and drifting with its answer hidden; now the mist parts.
                afterDelay(partDelay) {
                    withAnimation(.easeIn(duration: nameFadeIn)) {
                        resultRevealed = true
                    }
                }
            }
        }

        playHaptics()
    }

    /// Schedules the skin's haptic beats. Under Reduce Motion the motion is
    /// skipped, but the "you have your answer" tap still fires — at once.
    private func playHaptics() {
        let beats = skin.motion.revealHaptics
        if reduceMotion {
            if beats.contains(where: { $0.kind == .success }) {
                haptics.play(.success)
            }
            return
        }
        for beat in beats {
            afterDelay(beat.at) { haptics.play(beat.kind) }
        }
    }

    /// Runs `action` after `delay` seconds via a cancellable
    /// `DispatchWorkItem`, tracked in `scheduledWork`. Replaces raw
    /// `DispatchQueue.main.asyncAfter` calls, which had no way to be
    /// cancelled once scheduled.
    private func afterDelay(_ delay: Double, action: @escaping () -> Void) {
        let workItem = DispatchWorkItem(block: action)
        scheduledWork.append(workItem)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    /// Cancels every not-yet-fired delayed step scheduled by `afterDelay`.
    /// Called when this view disappears — the reveal is dismissed, or a
    /// fresh reroll tears this instance down via the caller's `.id()`.
    private func cancelScheduledWork() {
        for item in scheduledWork { item.cancel() }
        scheduledWork.removeAll()
    }
}

/// A simple downward-pointing triangle, used as the Prize Wheel's pointer —
/// it sits just above the wheel's rim (see the `.offset` at its call site)
/// with its tip aimed down into the wheel, like a real carnival wheel peg.
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
