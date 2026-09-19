import SwiftUI
import UIKit

/// The reveal screen's visual centerpiece: the shape (capsule / 8-ball /
/// wheel) plus the winner's name. For Gumball and the Wheel, the name sits
/// in its own card below the shape; for the 8-Ball, it appears inside the
/// ball's diamond window instead, so there's no separate name card — a real
/// structural difference in the source design, not just a color swap.
///
/// Each skin's intro animation is its own "toy" moment (PLAN.md §4.4):
/// Gumball pops in all at once; the 8-Ball's ball wobbles for ~1.1s before
/// the answer fades in; the Wheel actually spins to the winner's wedge
/// before its name card appears. Re-created fresh on every re-roll by the
/// caller's `.id(model.rerollToken)`, so the whole intro replays each
/// time — including when a reroll lands back on the same winner.
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
    @Environment(\.indReducedMotion) private var reduceMotion

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

            if skin.id != .eightBall {
                nameCard
                    .scaleEffect(nameCardVisible ? 1 : 0.9)
                    .opacity(nameCardVisible ? 1 : 0)
            }
        }
        .onAppear(perform: startIntroAnimation)
        .onDisappear(perform: cancelScheduledWork)
    }

    /// Whether the winner's name should be showing yet — for Gumball this
    /// is the same instant as the shape's pop-in; for the 8-Ball and Wheel
    /// it's deliberately delayed until their own intro animation finishes.
    private var nameCardVisible: Bool {
        switch skin.id {
        case .gumball: return popped
        case .prizeWheel: return resultRevealed
        case .eightBall: return false // unused — no separate name card
        }
    }

    @ViewBuilder
    private var entranceWrappedShape: some View {
        switch skin.id {
        case .gumball, .eightBall:
            shape
                .scaleEffect(popped ? 1 : 0.72)
                .rotationEffect(.degrees((popped ? 0 : -6) + (skin.id == .eightBall ? wobbleAngle : 0)))
                .opacity(popped ? 1 : 0)
        case .prizeWheel:
            // No bounce/scale here — that would fight visually with the
            // spin. Just a quick fade-in; the spin itself is the entrance.
            shape.opacity(popped ? 1 : 0)
        }
    }

    @ViewBuilder
    private var shape: some View {
        switch skin.id {
        case .gumball:
            ZStack {
                Circle().fill(
                    RadialGradient(
                        colors: [.white.opacity(0.85), skin.palette.accent],
                        center: UnitPoint(x: 0.34, y: 0.3),
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                Text("?!")
                    .font(skin.type.display(34))
                    .foregroundStyle(.white)
            }
            .frame(width: 176, height: 176)

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
        }
    }

    @ViewBuilder
    private var nameCard: some View {
        VStack(spacing: 8) {
            Text(winnerName)
                .font(skin.type.display(skin.id == .gumball ? 40 : 34))
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
        .background(skin.palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            if skin.id == .prizeWheel, let border = skin.palette.surfaceBorder {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(border, lineWidth: 4)
            }
        }
        .indShadow(nameCardShadow, cornerRadius: 28)
    }

    private var nameCardShadow: SkinShadowStyle {
        switch skin.id {
        case .gumball:
            // Was hardcoded to 0x17130F — the *Wheel's* ink color, not
            // Gumball's — so this shadow silently ignored any edit to
            // Gumball's own palette. `primaryText` is Gumball's actual
            // dark near-black, matching `CardStyle`'s and
            // `RevealActionStyle`'s equivalent shadows.
            return .soft(radius: 0, x: 0, y: 12, color: skin.palette.primaryText, opacity: 0.16)
        case .prizeWheel:
            return .hard(offset: CGSize(width: 6, height: 6), color: skin.palette.primaryText)
        case .eightBall:
            return .none // unused — 8-Ball has no separate name card
        }
    }

    // MARK: Intro animations
    //
    // Each skin plays its own haptic pattern alongside its intro animation
    // (PLAN.md Phase 6: "Haptics per skin"), and each collapses to a near-
    // instant, motion-free reveal under Reduce Motion — the long Wheel spin
    // in particular is exactly the kind of animation Reduce Motion exists
    // to skip, not just slow down or soften.

    private func startIntroAnimation() {
        cancelScheduledWork() // defensive — see `scheduledWork`'s doc comment

        switch skin.id {
        case .gumball:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            if reduceMotion {
                popped = true
            } else {
                withAnimation(.interpolatingSpring(stiffness: 170, damping: 14).delay(0.05)) {
                    popped = true
                }
            }
            // Delayed slightly from the soft impact above — firing both
            // immediately back to back (regardless of Reduce Motion, since
            // neither call is conditioned on it) means the Taptic Engine
            // typically only plays the second one, silently swallowing
            // the first.
            afterDelay(0.15) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }

        case .eightBall:
            // `repeatCount(6, autoreverses: true)` below takes 6 full
            // back-and-forth cycles × 0.09s × 2 = 1.08s to run its course.
            let wobbleDuration = 0.09 * 2 * 6
            if reduceMotion {
                popped = true
                resultRevealed = true
            } else {
                withAnimation(.interpolatingSpring(stiffness: 170, damping: 14)) {
                    popped = true
                }
                withAnimation(.easeInOut(duration: 0.09).repeatCount(6, autoreverses: true)) {
                    wobbleAngle = 7
                }
                let rigid = UIImpactFeedbackGenerator(style: .rigid)
                rigid.impactOccurred()
                for tick in 1..<6 {
                    afterDelay(Double(tick) * 0.09) {
                        rigid.impactOccurred(intensity: 0.6)
                    }
                }
                // Wait for the wobble to finish naturally instead of
                // cutting it off mid-swing — this used to force
                // `wobbleAngle` back to 0 at a fixed 0.6s, well before the
                // 1.08s the animation above actually takes, producing a
                // visible snap. It already ends back at 0 on its own (6 is
                // a whole number of round trips), so this assignment is
                // now just a harmless no-op safety net.
                afterDelay(wobbleDuration) {
                    wobbleAngle = 0
                    withAnimation(.easeIn(duration: 0.35)) {
                        resultRevealed = true
                    }
                }
            }
            let revealDelay = reduceMotion ? 0 : wobbleDuration
            afterDelay(revealDelay) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }

        case .prizeWheel:
            let target = wheelTargetSpinAngle(
                wedgeCount: wedgeCount, winnerIndex: winnerWedgeIndex,
                extraSpins: reduceMotion ? 0 : 4
            )
            if reduceMotion {
                popped = true
                spinAngle = target
                resultRevealed = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    popped = true
                }
                withAnimation(.timingCurve(0.15, 0.85, 0.25, 1, duration: 2.8)) {
                    spinAngle = target
                }
                playWheelTickHaptics(duration: 2.8)
                afterDelay(2.8) {
                    withAnimation(.interpolatingSpring(stiffness: 170, damping: 14)) {
                        resultRevealed = true
                    }
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        }
    }

    /// Fires `.selection` ticks with decreasing frequency over `duration`,
    /// to feel like a wheel slowing down and crossing wedge boundaries —
    /// an approximation of the motion, not tied to the exact wedge count.
    private func playWheelTickHaptics(duration: Double) {
        let generator = UISelectionFeedbackGenerator()
        var elapsed = 0.0
        var interval = 0.06
        while elapsed < duration {
            afterDelay(elapsed) {
                generator.selectionChanged()
            }
            elapsed += interval
            interval *= 1.18 // slows down, mimicking deceleration
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
