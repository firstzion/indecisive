import SwiftUI
import UIKit

/// The full-screen reveal: kicker, centrepiece + winner name, confetti, and
/// the accept/re-roll actions.
struct RevealView: View {
    let model: RevealModel

    @Environment(\.skin) private var skin
    @Environment(\.dismiss) private var dismiss
    @Environment(\.indReducedMotion) private var reduceMotion
    /// Whether the skin's intro has run its course, so the winner is
    /// actually on screen. Set by `announceWinnerOnceLegible()`.
    @State private var introHasFinished = false

    /// Whether the accept / re-roll buttons (and a shake) should do
    /// anything yet. You can't lock in — or reject — an answer you can't
    /// see, and on the Wheel "can't see it yet" lasts the whole 2.8 s spin.
    ///
    /// `reduceMotion` short-circuits it rather than waiting for the state
    /// above, so the very first render is already correct in the case where
    /// there is no intro to wait through. (That also keeps the reveal
    /// snapshots — which all render under Reduce Motion — showing the
    /// settled screen rather than a transient disabled one.)
    private var actionsEnabled: Bool {
        reduceMotion || introHasFinished
    }

    var body: some View {
        ZStack {
            skin.palette.revealBackground.ignoresSafeArea()
            RevealGlow(skin: skin).offset(y: -80)
            Confetti(skin: skin).ignoresSafeArea()

            // A ScrollView, not a fixed VStack with Spacers either side:
            // at very large Dynamic Type sizes the centrepiece's text can
            // outgrow the screen, and this scrolls instead of clipping
            // (PLAN.md Phase 6: "the reveal card scrolls if needed"). The
            // GeometryReader + minHeight keeps it vertically centered at
            // ordinary sizes, where it fits with room to spare.
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 18) {
                        RevealKicker(skin: skin)
                        RevealCentrepiece(
                            skin: skin,
                            winnerName: model.winner.name,
                            candidateCount: model.list.items.count,
                            winnerWedgeIndex: winnerWedgeIndex,
                            wedgeCount: wedgeCount
                        )
                        // Re-trigger the intro animation on every re-roll —
                        // keyed off `rerollToken`, not `winner.id`, so a
                        // reroll that lands back on the *same* item (a
                        // one-item list, or the exclusion pool resetting)
                        // still replays instead of silently doing nothing.
                        .id(model.rerollToken)
                    }
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                }
            }
            .safeAreaInset(edge: .top) { header }
            .safeAreaInset(edge: .bottom) {
                RevealActions(skin: skin, isEnabled: actionsEnabled, onAccept: accept, onReroll: model.reroll)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(skin.reveal.colorScheme)
        .onShake {
            // Only a skin that picks on shake (the 8-Ball) cares about physical
            // shakes — matches its own "SHAKE AGAIN" re-roll button. Held off
            // until the answer is readable for the same reason the buttons
            // are: a shaky hand would otherwise stack re-rolls behind the one
            // still playing, each recording a rejection of an answer nobody
            // ever saw.
            guard skin.traits.shakeToPick, actionsEnabled else { return }
            model.reroll()
        }
        // Keyed on `rerollToken`, so every re-roll restarts the wait — and
        // `task(id:)` cancels the previous one for us when the token changes
        // or this screen goes away. (This replaces a hand-managed
        // `DispatchWorkItem`, which existed only to be cancellable: without
        // that, a stale announcement up to ~2.9 s out could fire over a
        // screen the user had already dismissed.)
        .task(id: model.rerollToken) { await announceWinnerOnceLegible() }
    }

    /// Waits out the skin's intro, then lets the actions work and tells
    /// VoiceOver the answer — both at the moment the winner is actually on
    /// screen (`announcementDelay`; PLAN.md Phase 6: "the reveal announces
    /// the winner"), rather than the instant the model picked it, which for
    /// the Wheel is ~2.8 s before its name appears.
    private func announceWinnerOnceLegible() async {
        let delay = Self.announcementDelay(for: skin, reduceMotion: reduceMotion)
        if delay > 0 {
            introHasFinished = false
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
        }
        introHasFinished = true
        UIAccessibility.post(notification: .announcement, argument: "\(skin.copy.revealKicker). \(model.winner.name).")
    }

    /// How long after the reveal appears VoiceOver announces the winner: once it
    /// is actually on screen, which is when the skin's own intro says it is — the
    /// very numbers `RevealCentrepiece` animates with, so the two can't drift
    /// apart. At once under Reduce Motion, which skips the intro. Pure data, so
    /// `nonisolated`, and internal so the tests can check it.
    nonisolated static func announcementDelay(for skin: Skin, reduceMotion: Bool) -> Double {
        reduceMotion ? 0 : skin.motion.revealIntro.winnerLegibleAfter
    }

    private var wedgeCount: Int {
        wheelWedgeCount(forItemCount: model.list.items.count)
    }

    private var winnerWedgeIndex: Int {
        let ordered = model.list.orderedItems
        guard let index = ordered.firstIndex(where: { $0.id == model.winner.id }) else { return 0 }
        return index
    }

    private var header: some View {
        HStack {
            Text(model.list.name)
                .font(skin.type.body(15, weight: .bold))
                .foregroundStyle(skin.reveal.headerText)
            Spacer()
            SkinIconButton(skin: skin, glyph: "✕", accessibilityLabel: "Close", variant: .dismiss, size: 32) {
                dismiss()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func accept() {
        model.accept()
        dismiss()
    }
}
