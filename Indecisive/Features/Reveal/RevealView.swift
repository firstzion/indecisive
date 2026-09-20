import SwiftUI
import UIKit

/// The full-screen reveal: kicker, centrepiece + winner name, confetti, and
/// the accept/re-roll actions.
struct RevealView: View {
    let model: RevealModel

    @Environment(\.skin) private var skin
    @Environment(\.dismiss) private var dismiss
    @Environment(\.indReducedMotion) private var reduceMotion
    /// The pending `scheduleWinnerAnnouncement()` work, kept so it can be
    /// cancelled — otherwise a stale VoiceOver announcement (up to ~2.9s
    /// out, for the Wheel) can fire after the user has already dismissed
    /// this screen or rerolled again.
    @State private var announcementWorkItem: DispatchWorkItem?

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
                RevealActions(skin: skin, onAccept: accept, onReroll: model.reroll)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(skin.reveal.colorScheme)
        .onShake {
            // Only a skin that picks on shake (the 8-Ball) cares about physical
            // shakes — matches its own "SHAKE AGAIN" re-roll button.
            guard skin.traits.shakeToPick else { return }
            model.reroll()
        }
        .onAppear { scheduleWinnerAnnouncement() }
        .onChange(of: model.rerollToken) { _, _ in scheduleWinnerAnnouncement() }
        .onDisappear { announcementWorkItem?.cancel() }
    }

    /// VoiceOver announces the winner once it's actually visible — timed to
    /// each skin's own intro animation (`announcementDelay`; PLAN.md Phase 6:
    /// "the reveal announces the winner"), rather than the instant the model
    /// picks it, which for the Wheel is ~2.8s before its name is on screen.
    private func scheduleWinnerAnnouncement() {
        // A reroll before the previous announcement fired would otherwise
        // stack a second one on top of it; cancel whatever's pending first.
        announcementWorkItem?.cancel()

        let delay = Self.announcementDelay(for: skin, reduceMotion: reduceMotion)
        let announcement = "\(skin.copy.revealKicker). \(model.winner.name)."
        let workItem = DispatchWorkItem {
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
        announcementWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
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
