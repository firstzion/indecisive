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
/// The two decisions a row swipe makes, as pure functions of the drag — so
/// they can be unit tested without a gesture, and so the threshold isn't a
/// magic number buried in a view.
enum SwipeToDelete {
    /// How far left a release has to be past to count as "far enough" —
    /// comfortably short of `XCUIElement.swipeLeft()`'s own travel (it
    /// swipes ~80% of the element's width), so the UI test that exercises
    /// this exact gesture reliably commits.
    static let commitThreshold: CGFloat = -120

    /// Whether a drag has moved further across than down — a row swipe
    /// rather than the beginnings of a scroll. Vertical drags are left
    /// alone so the enclosing `ScrollView` still scrolls normally.
    static func isHorizontal(_ translation: CGSize) -> Bool {
        abs(translation.width) > abs(translation.height)
    }

    /// How far the row is pulled for a drag of `translation`. Rightward
    /// drags don't pull it anywhere; there is nothing to the right.
    static func offset(for translation: CGSize) -> CGFloat {
        min(0, translation.width)
    }

    /// Whether releasing here should ask to delete the row.
    static func commits(_ translation: CGSize) -> Bool {
        offset(for: translation) < commitThreshold
    }
}

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

    /// "A drag is in progress", but as `@GestureState`, which SwiftUI resets
    /// on its own when a gesture ends **or is cancelled**.
    ///
    /// `onEnded` covers only the first. A drag that the enclosing
    /// `ScrollView` takes over, or that the system interrupts, simply never
    /// ends — and the two `@State`s above would then keep whatever the last
    /// `onChanged` left them: `offset` frozen mid-swipe with the red
    /// backdrop showing, and `isSwiping` stuck `true`, which leaves
    /// `.disabled(isSwiping)` below holding that row un-tappable and
    /// un-navigable for good. Watching this reset instead means the row
    /// always springs back, however the drag ended.
    @GestureState private var isDragging = false

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
                        .updating($isDragging) { _, state, _ in state = true }
                        .onChanged { value in
                            // Only track predominantly-horizontal movement —
                            // vertical drags pass straight through so the
                            // enclosing `ScrollView` still scrolls normally.
                            guard SwipeToDelete.isHorizontal(value.translation) else { return }
                            isSwiping = true
                            offset = SwipeToDelete.offset(for: value.translation)
                        }
                        .onEnded { value in
                            // Decided from the gesture's own final
                            // translation rather than from `offset`, which
                            // `springBack()` may already have reset: the two
                            // run in the same update and their order isn't
                            // ours to choose.
                            guard SwipeToDelete.isHorizontal(value.translation) else { return }
                            if SwipeToDelete.commits(value.translation) {
                                onDeleteRequested()
                            }
                        }
                )
                // Fires when the drag ends *and* when it is cancelled — see
                // `isDragging`. Springing back from here rather than from
                // `onEnded` is what keeps an interrupted swipe from leaving
                // the row stranded and disabled.
                .onChange(of: isDragging) { _, dragging in
                    guard !dragging else { return }
                    springBack()
                }
                // The swipe is a gesture VoiceOver and Switch Control can't
                // perform, so offer the same request as a named action on the
                // row (it still asks for confirmation, never deletes outright).
                .accessibilityAction(named: "Delete") { onDeleteRequested() }
        }
    }

    /// Returns the row to resting and lets it be tapped again.
    private func springBack() {
        isSwiping = false
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            offset = 0
        }
    }
}
