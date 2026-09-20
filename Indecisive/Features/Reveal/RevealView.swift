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
        .preferredColorScheme(revealColorScheme)
        .onShake {
            // Only a skin that picks on shake (the 8-Ball) cares about physical
            // shakes — matches its own "SHAKE AGAIN" re-roll button.
            guard skin.shakeToPick else { return }
            model.reroll()
        }
        .onAppear { scheduleWinnerAnnouncement() }
        .onChange(of: model.rerollToken) { _, _ in scheduleWinnerAnnouncement() }
        .onDisappear { announcementWorkItem?.cancel() }
    }

    /// VoiceOver announces the winner once it's actually visible — timed to
    /// roughly match each skin's own intro animation (PLAN.md Phase 6: "the
    /// reveal announces the winner"), rather than the instant the model
    /// picks it, which for the Wheel is ~2.8s before its name is on screen.
    private func scheduleWinnerAnnouncement() {
        // A reroll before the previous announcement fired would otherwise
        // stack a second one on top of it; cancel whatever's pending first.
        announcementWorkItem?.cancel()

        let delay: Double
        if reduceMotion {
            delay = 0
        } else {
            switch skin.id {
            case .eightBall: delay = 1.0
            case .prizeWheel: delay = 2.9
            case .gashapon: delay = 0.85 // the lid finishes springing off
            }
        }
        let announcement = "\(skin.copy.revealKicker). \(model.winner.name)."
        let workItem = DispatchWorkItem {
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
        announcementWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
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
                .foregroundStyle(headerTextColor)
            Spacer()
            SkinIconButton(skin: skin, glyph: "✕", accessibilityLabel: "Close", variant: .dismiss, size: 32) {
                dismiss()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    /// The reveal background is loud and skin-specific (near-black, bright
    /// yellow or cyan), so the header label's color and the
    /// screen's overall color scheme aren't derivable from a single token —
    /// each skin picked its own readable combination in the source design.
    private var headerTextColor: Color {
        switch skin.id {
        case .eightBall: return skin.palette.secondaryText
        case .prizeWheel: return skin.palette.primaryText
        case .gashapon: return GashaponPaint.revealInk
        }
    }

    private var revealColorScheme: ColorScheme {
        switch skin.id {
        case .eightBall: return .dark
        case .prizeWheel, .gashapon: return .light
        }
    }

    private func accept() {
        model.accept()
        dismiss()
    }
}
