import SwiftUI
import SwiftData
import UIKit

/// The list-detail screen: hero, items card, add row, and the pinned
/// "Pick For Me" CTA. Also owns edit mode (rename items, delete items,
/// reorder, delete the whole list) and starting a reveal.
struct ListDetailView: View {
    @Environment(\.skin) private var skin
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var list: PickList

    @State private var isEditing = false
    @State private var isAddingItem = false
    @State private var newItemName = ""
    @State private var revealModel: RevealModel?
    @State private var showingDeleteConfirmation = false
    @FocusState private var isAddFieldFocused: Bool
    /// `list.name`'s value from just before this edit session started, so
    /// `commitEdits()` has something sane to fall back to if the user
    /// clears the title entirely instead of just retyping it — see
    /// `commitEdits()`.
    @State private var nameBeforeEditing = ""
    /// Scales `backButton`'s "‹" with Dynamic Type — a plain
    /// `.font(.system(size: 24))` literal never grows, so the glyph would
    /// stay pinned at the same physical size while "Lists" next to it scales.
    @ScaledMetric private var backChevronSize: CGFloat = 24

    /// Every change this screen makes to the list goes through here, so the
    /// logic is reachable from a unit test rather than sealed inside a `View`.
    private var editor: ListEditor {
        ListEditor(context: modelContext)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero
                itemsCard
                addRow
                if isEditing {
                    deleteListButton
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(skin.palette.background)
        .safeAreaInset(edge: .bottom) { ctaArea }
        .navigationBarBackButtonHidden(true)
        .restoresInteractivePopGesture()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { backButton }
            ToolbarItem(placement: .principal) { titleView }
            ToolbarItem(placement: .navigationBarTrailing) { editButton }
        }
        .alert("Delete “\(list.name)”?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive, action: deleteList)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the list and everything in it. This can't be undone.")
        }
        .onShake(canClaimFocus: !isEditing && !isAddFieldFocused) {
            // "ASK. SHAKE. OBEY." — a skin that picks on shake (the 8-Ball) lets
            // you shake instead of tapping the CTA. Other skins ignore it. No-op
            // while editing or if a reveal is already up, same as the CTA being
            // disabled/covered in those states.
            guard skin.traits.shakeToPick, !isEditing, !list.items.isEmpty, revealModel == nil else { return }
            startReveal()
        }
        .fullScreenCover(item: $revealModel) { model in
            RevealView(model: model)
        }
        // Safety net for `commitEdits()` — catches leaving mid-rename via
        // the back button or the swipe gesture (just restored above)
        // without ever tapping "Done", not just the normal Done-tap path
        // in `editButton`.
        //
        // Gated on actually being mid-edit. It used to run unconditionally,
        // which meant simply *looking* at a list and going back rewrote its
        // name and every item's name to the values they already held —
        // dirtying the model and waking autosave and every `@Query`
        // observing it, for nothing. Tapping "Done" has already committed by
        // the time this runs, so `isEditing` is false there too.
        .onDisappear {
            guard isEditing else { return }
            commitEdits()
        }
    }

    // MARK: Toolbar

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            HStack(spacing: 2) {
                Text("‹").font(.system(size: backChevronSize, weight: .bold))
                Text("Lists").font(skin.type.body(16, weight: .bold))
            }
            .foregroundStyle(skin.palette.accentText)
        }
        .accessibilityLabel("Lists")
        .accessibilityIdentifier("backToListsButton")
    }

    @ViewBuilder
    private var titleView: some View {
        if isEditing {
            TextField("List name", text: $list.name)
                .font(skin.type.display(17, weight: .bold, relativeTo: .body))
                .foregroundStyle(skin.palette.primaryText)
                .multilineTextAlignment(.center)
                .frame(width: 180)
        } else {
            Text(list.name)
                .font(skin.type.display(17, weight: .bold, relativeTo: .body))
                .foregroundStyle(skin.palette.primaryText)
        }
    }

    private var editButton: some View {
        Button(isEditing ? "Done" : "Edit") {
            if isEditing {
                // Take focus off whatever field has it *before* the toggle
                // below removes that field from the hierarchy. Without this,
                // tapping "Done" mid-rename made SwiftUI commit the field's
                // text into the model during its own view update and log
                // "Modifying state during view update, this will cause
                // undefined behavior." The value written was the one already
                // there, so nothing visibly broke — but the message means
                // what it says, and this is the ordering it's asking for.
                endTextEditing()
                commitEdits()
            } else {
                nameBeforeEditing = list.name
            }
            isEditing.toggle()
        }
        .font(skin.type.body(16, weight: .bold))
        .foregroundStyle(skin.palette.accentText)
        .accessibilityIdentifier("editModeButton")
    }

    // MARK: Content

    private var hero: some View {
        HStack(alignment: .center, spacing: 14) {
            HeroBadge(skin: skin, flavorIndex: list.flavorIndex, itemCount: list.items.count, size: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(skin.copy.detailHeadline(list.items.count))
                    .font(skin.type.display(24, weight: .extrabold))
                    .foregroundStyle(skin.palette.primaryText)
                if let lastPick = list.lastAcceptedPick {
                    Text(skin.copy.lastPickLine(lastPick.itemName, lastPick.date))
                        .font(skin.type.body(13, weight: .semibold))
                        .foregroundStyle(skin.palette.secondaryText)
                        .accessibilityIdentifier("lastPickLine")
                }
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var itemsCard: some View {
        let items = list.orderedItems
        if items.isEmpty {
            emptyItemsPlaceholder
        } else {
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    ItemRow(
                        skin: skin,
                        item: item,
                        index: index,
                        isEditing: isEditing,
                        canMoveUp: index > 0,
                        canMoveDown: index < items.count - 1,
                        onDelete: { deleteItem(item) },
                        onMoveUp: { moveItem(item, by: -1) },
                        onMoveDown: { moveItem(item, by: 1) }
                    )
                    if index < items.count - 1 {
                        Divider().overlay(skin.palette.divider)
                    }
                }
            }
            .padding(.horizontal, 16)
            .indCard(skin)
        }
    }

    private var emptyItemsPlaceholder: some View {
        VStack(spacing: 6) {
            Text(skin.copy.emptyStateTitle)
                .font(skin.type.display(18, weight: .bold, relativeTo: .body))
                .foregroundStyle(skin.palette.primaryText)
                .multilineTextAlignment(.center)
            Text(skin.copy.emptyStateMessage)
                .font(skin.type.body(13, weight: .semibold))
                .foregroundStyle(skin.palette.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .indCard(skin)
    }

    @ViewBuilder
    private var addRow: some View {
        if isAddingItem {
            HStack(spacing: 10) {
                TextField(skin.copy.addRow, text: $newItemName)
                    .font(skin.type.body(15, weight: .semibold))
                    .foregroundStyle(skin.palette.primaryText)
                    .focused($isAddFieldFocused)
                    .submitLabel(.done)
                    .onSubmit(commitNewItem)
                    .accessibilityIdentifier("newItemNameField")
                Button("Add", action: commitNewItem)
                    .font(skin.type.body(15, weight: .bold))
                    .foregroundStyle(skin.palette.accentText)
                    .disabled(newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("addItemButton")
            }
            .padding(.vertical, 13)
            .padding(.horizontal, 16)
            .overlay {
                RoundedRectangle(cornerRadius: skin.shape.dashedCornerRadius, style: .continuous)
                    .strokeBorder(skin.palette.dashedBorder, style: StrokeStyle(lineWidth: skin.shape.dashedBorderWidth, dash: [7, 6]))
            }
        } else {
            Button {
                isAddingItem = true
                isAddFieldFocused = true
            } label: {
                DashedAddRow(skin: skin, label: skin.copy.addRow)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("startAddItemButton")
        }
    }

    private var deleteListButton: some View {
        Button(role: .destructive) {
            showingDeleteConfirmation = true
        } label: {
            Text("Delete this list")
                .font(skin.type.body(15, weight: .bold))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private var ctaArea: some View {
        VStack(spacing: 10) {
            Text(skin.copy.ctaCaption)
                .font(skin.type.body(13, weight: .semibold))
                .foregroundStyle(skin.palette.tertiaryText)
                .tracking(0.5)
                // Decorative flourish, redundant with the button's own
                // fuller label below — VoiceOver shouldn't read both.
                .accessibilityHidden(true)

            Button(skin.copy.ctaLabel, action: startReveal)
                .buttonStyle(PrimaryCTAStyle(skin: skin))
                .disabled(list.items.isEmpty)
                .opacity(list.items.isEmpty ? 0.5 : 1)
                .accessibilityLabel(pickButtonAccessibilityLabel)
                .accessibilityIdentifier("pickForMeButton")
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background {
            LinearGradient(
                colors: [skin.palette.background.opacity(0), skin.palette.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
    }

    /// e.g. "Pick for me, chooses randomly from 14 items" — the exact
    /// phrasing PLAN.md Phase 6 calls out for this button.
    private var pickButtonAccessibilityLabel: String {
        let count = list.items.count
        guard count > 0 else { return "\(skin.copy.ctaLabel). Add items to this list first." }
        return "\(skin.copy.ctaLabel), chooses randomly from \(count) item\(count == 1 ? "" : "s")"
    }

    // MARK: Actions

    /// Resigns first responder wherever it currently is, flushing any
    /// in-progress text edit into its binding. There is no `@FocusState` to
    /// clear instead: the editable fields are the list title in the toolbar
    /// and `ItemRow`'s own `TextField`s, which bind straight to the model
    /// from inside a child view.
    private func endTextEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func startReveal() {
        let service = PickService(context: modelContext)
        revealModel = RevealModel(list: list, service: service)
    }

    private func commitNewItem() {
        guard editor.addItem(named: newItemName, to: list) != nil else { return }
        newItemName = ""
        isAddFieldFocused = true  // stay focused for quickly adding several items
    }

    private func deleteItem(_ item: PickItem) {
        editor.delete(item, from: list)
    }

    private func moveItem(_ item: PickItem, by offset: Int) {
        editor.move(item, in: list, by: offset)
    }

    /// Cleans up whatever edit-mode left behind — see
    /// `ListEditor.commitEdits(to:fallingBackTo:)`. Called both from "Done"
    /// and from `onDisappear`, so leaving the screen mid-rename via the back
    /// button (or the swipe gesture) is covered too.
    private func commitEdits() {
        editor.commitEdits(to: list, fallingBackTo: nameBeforeEditing)
    }

    private func deleteList() {
        // Leave edit mode first. "Delete this list" only exists *in* edit
        // mode, so `onDisappear`'s `commitEdits()` would otherwise still be
        // armed as this screen pops — and since the delete below is
        // deferred by a run-loop turn, that commit lands *after* it,
        // ordering a write to `list.name` and every `item.name` after the
        // delete of the very object it writes to.
        isEditing = false

        // Dismiss first, *then* delete — deleting the SwiftData model
        // before dismissing risks `body` re-evaluating (it reads
        // `list.name`/`list.items` in the toolbar, alert and hero) against
        // an object that's already been removed from the context, which
        // can crash. Deferring the delete to the next run loop turn gives
        // the dismiss/pop transition a chance to start first.
        dismiss()
        let target = list
        let editor = self.editor
        DispatchQueue.main.async {
            editor.delete(target)
        }
    }
}
