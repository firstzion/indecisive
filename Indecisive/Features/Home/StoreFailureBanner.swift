import SwiftUI

/// Shown on Home for as long as the app is running on the throwaway in-memory
/// store it fell back to when the real one wouldn't open.
///
/// There was an alert for this already, and it is still there — but an alert
/// fires once, says "your previous lists may be lost", and is then dismissed
/// and gone. The part it can't express is the part that keeps costing the user
/// something: *everything they do from here on is also going to vanish.* They
/// could spend the session building three new lists, quit, and find an empty
/// app with nothing having warned them. That's the worst outcome this app has,
/// and it was silent.
///
/// So the alert explains what happened, once, and this says what is still true,
/// for as long as it is true.
///
/// Deliberately skinned rather than a system-red banner: it sits directly under
/// the app's own title on every skin, and a stock alert-red bar would look like
/// a bug in three of the four. `destructive` is the skin's own "something is
/// wrong" colour and is already contrast-checked against `surface`.
struct StoreFailureBanner: View {
    let skin: Skin

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(skin.palette.destructive)

            VStack(alignment: .leading, spacing: 2) {
                Text("Not saving")
                    .font(skin.type.compactTitle(15))
                    .foregroundStyle(skin.palette.primaryText)
                Text("Your saved data couldn't be opened. Anything you add now will be gone when you quit.")
                    .font(skin.type.body(13, weight: .semibold))
                    .foregroundStyle(skin.palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .indCard(skin)
        // One stop for VoiceOver, not three, and read as a warning rather than
        // as two unrelated bits of text under the title.
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("storeFailureBanner")
    }
}
