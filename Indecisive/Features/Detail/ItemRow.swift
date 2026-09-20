import SwiftUI

/// One item inside a list's card. Outside edit mode it's just a marker +
/// name; in edit mode the marker becomes a delete button, the name becomes
/// an editable field, and reorder controls appear.
///
/// This uses simple tap-to-delete / tap-to-reorder controls rather than
/// native swipe-to-delete or drag-to-reorder. The item card is a custom
/// view (built with `CardStyle` to match the design's shadows/borders
/// exactly, see PLAN.md §4.2), not a SwiftUI `List`, and native swipe/drag
/// gestures only come for free inside a `List`. Rebuilding the card look
/// inside a heavily-restyled `List` was judged not worth it for Phase 3;
/// it's a reasonable follow-up if real swipe/drag interactions matter more
/// than the exact card shadow.
struct ItemRow: View {
    let skin: Skin
    /// `@Bindable` so edit mode's name field binds straight to the model
    /// (`$item.name`) — the same live two-way binding `ListDetailView` uses for
    /// the list's own title — instead of a rename closure threaded in from outside.
    @Bindable var item: PickItem
    let index: Int
    let isEditing: Bool
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onDelete: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void

    // `@ScaledMetric` instead of a plain `.font(.system(size: N))` literal —
    // the latter never grows with Dynamic Type, so these interactive icons
    // would stay pinned at the same physical size while every text label
    // around them scales up.
    @ScaledMetric private var deleteIconSize: CGFloat = 18
    @ScaledMetric private var reorderIconSize: CGFloat = 12

    var body: some View {
        HStack(spacing: 12) {
            if isEditing {
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                        .font(.system(size: deleteIconSize))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete \(spokenName)")
                .accessibilityIdentifier("deleteItemButton-\(index)")
            } else {
                // `RowMarker` still takes position and flavour-color as two
                // separate parameters (it's the more reusable primitive),
                // even though this call site — like every other one in the
                // app — always has the same value for both.
                RowMarker(skin: skin, index: index, flavorIndex: index)
            }

            if isEditing {
                TextField("Item name", text: $item.name)
                    .font(skin.type.body(15, weight: .semibold))
                    .foregroundStyle(skin.palette.primaryText)
                    .accessibilityIdentifier("itemNameField-\(index)")
            } else {
                Text(item.name)
                    .font(skin.type.body(15, weight: .semibold))
                    .foregroundStyle(skin.palette.primaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if isEditing {
                VStack(spacing: 2) {
                    Button(action: onMoveUp) {
                        Image(systemName: "chevron.up")
                    }
                    .disabled(!canMoveUp)
                    .accessibilityLabel("Move \(spokenName) up")
                    .accessibilityIdentifier("moveItemUpButton-\(index)")

                    Button(action: onMoveDown) {
                        Image(systemName: "chevron.down")
                    }
                    .disabled(!canMoveDown)
                    .accessibilityLabel("Move \(spokenName) down")
                    .accessibilityIdentifier("moveItemDownButton-\(index)")
                }
                .buttonStyle(.plain)
                .font(.system(size: reorderIconSize, weight: .bold))
                .foregroundStyle(skin.palette.chevron)
            }
        }
        .padding(.vertical, 12)
    }

    /// What VoiceOver calls this item in a control's label. Falls back for the
    /// moment the field is empty mid-edit (backspacing to retype), so a label
    /// never reads "Delete " with nothing after it.
    private var spokenName: String {
        item.name.isEmpty ? "untitled item" : item.name
    }
}
