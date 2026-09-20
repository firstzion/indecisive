import SwiftUI

/// A Mail-style "pull to delete" wrapper: dragging `content` left reveals a
/// red backdrop underneath it, and releasing past `commitThreshold` calls
/// `onDeleteRequested` (expected to ask for confirmation, not delete
/// outright) before springing back to resting. Releasing short of the
/// threshold just springs back with no effect.
///
/// Deliberately not `List` + `.swipeActions` — that needs a `List`, and in
/// this app a `List`-based Home screen turned out to leave every row
/// permanently un-hittable after any `.sheet` (e.g. the "New list" sheet)
/// dismissed, in this iOS/Xcode version. Rather than carry that bug for the
/// sake of the native API, this hand-rolls the same gesture on top of the
/// plain `ScrollView`/`VStack` layout every other screen already uses.
struct SwipeToDeleteRow<Content: View>: View {
    let skin: Skin
    let onDeleteRequested: () -> Void
    @ViewBuilder var content: () -> Content

    @State private var offset: CGFloat = 0

    /// `true` from the moment a horizontal drag is recognised until the
    /// finger lifts. Tracked separately from `offset` because that stays
    /// clamped at 0 for a rightward drag, which shouldn't count as a tap on
    /// the row either — see the `.disabled` below.
    @State private var isSwiping = false

    /// How far left a release has to be past to count as "far enough" —
    /// comfortably short of `XCUIElement.swipeLeft()`'s own travel (it
    /// swipes ~80% of the element's width), so the UI test that exercises
    /// this exact gesture reliably commits.
    private let commitThreshold: CGFloat = -120

    var body: some View {
        ZStack(alignment: .trailing) {
            if offset < 0 {
                RoundedRectangle(cornerRadius: skin.shape.cardRadius, style: .continuous)
                    .fill(skin.palette.destructive)
                    .overlay(alignment: .trailing) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(skin.palette.onDestructive)
                            .padding(.trailing, 28)
                    }
                    .accessibilityHidden(true)
            }
            content()
                // The row moves *with* the finger, so from the point of view
                // of a `NavigationLink` inside `content` the touch never
                // leaves its bounds: its press is never cancelled and it
                // fires when the finger lifts. Without this, a swipe both
                // raised the delete confirmation *and* pushed into the list
                // behind it (and a swipe too short to delete still opened
                // the list). Disabling the content for the length of a swipe
                // drops that pending activation. Applied before `.offset`
                // and the gesture below, so the drag itself is unaffected.
                .disabled(isSwiping)
                .offset(x: offset)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 12)
                        .onChanged { value in
                            // Only track predominantly-horizontal, leftward
                            // movement — vertical drags pass straight
                            // through so the enclosing `ScrollView` still
                            // scrolls normally.
                            guard abs(value.translation.width) > abs(value.translation.height) else { return }
                            isSwiping = true
                            offset = min(0, value.translation.width)
                        }
                        .onEnded { value in
                            isSwiping = false
                            if offset < commitThreshold {
                                onDeleteRequested()
                            }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                offset = 0
                            }
                        }
                )
                // The swipe is a gesture VoiceOver and Switch Control can't
                // perform, so offer the same request as a named action on the
                // row (it still asks for confirmation, never deletes outright).
                .accessibilityAction(named: "Delete") { onDeleteRequested() }
        }
    }
}
