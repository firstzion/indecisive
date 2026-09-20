import SwiftUI
import SwiftData

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
        .onDisappear(perform: commitEdits)
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
            .foregroundStyle(skin.palette.accent)
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
                commitEdits()
            } else {
                nameBeforeEditing = list.name
            }
            isEditing.toggle()
        }
        .font(skin.type.body(16, weight: .bold))
        .foregroundStyle(skin.palette.accent)
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
                    .foregroundStyle(skin.palette.accent)
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

    private func startReveal() {
        let service = PickService(context: modelContext)
        revealModel = RevealModel(list: list, service: service)
    }

    private func commitNewItem() {
        let trimmed = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let nextOrder = (list.items.map(\.sortOrder).max() ?? -1) + 1
        let item = PickItem(name: trimmed, sortOrder: nextOrder)
        list.items.append(item)
        modelContext.insert(item)
        newItemName = ""
        isAddFieldFocused = true // stay focused for quickly adding several items
    }

    private func deleteItem(_ item: PickItem) {
        list.items.removeAll { $0.id == item.id }
        modelContext.delete(item)
        renormalizeSortOrder()
    }

    private func moveItem(_ item: PickItem, by offset: Int) {
        var ordered = list.orderedItems
        guard let index = ordered.firstIndex(where: { $0.id == item.id }) else { return }
        let newIndex = index + offset
        guard ordered.indices.contains(newIndex) else { return }
        ordered.swapAt(index, newIndex)
        for (i, orderedItem) in ordered.enumerated() {
            orderedItem.sortOrder = i
        }
    }

    private func renormalizeSortOrder() {
        for (i, item) in list.orderedItems.enumerated() {
            item.sortOrder = i
        }
    }

    /// Cleans up whatever edit-mode left behind: trims stray whitespace
    /// from every name, and — unlike `NewListSheet`'s and `commitNewItem`'s
    /// create flows, which simply refuse an empty name outright — falls
    /// back to something non-empty instead, since these are live two-way
    /// bindings straight into the model (`$list.name`, and `ItemRow`'s
    /// `$item.name`). Rejecting an empty value on every
    /// keystroke there would make backspacing to fully clear a field (to
    /// retype it) impossible: the field would just snap back to the old
    /// text on the very last backspace. So instead, typing freely
    /// (including through an empty in-between state) stays fully live,
    /// and this only fixes up whatever's left once editing actually ends —
    /// called both from "Done" and from `onDisappear`, so leaving the
    /// screen mid-rename via the back button (or the swipe gesture) is
    /// covered too, not just an explicit Done tap.
    private func commitEdits() {
        let trimmedTitle = list.name.trimmingCharacters(in: .whitespacesAndNewlines)
        list.name = trimmedTitle.isEmpty ? nameBeforeEditing : trimmedTitle

        for item in list.items {
            let trimmed = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            item.name = trimmed.isEmpty ? "Untitled" : trimmed
        }
    }

    private func deleteList() {
        // Dismiss first, *then* delete — deleting the SwiftData model
        // before dismissing risks `body` re-evaluating (it reads
        // `list.name`/`list.items` in the toolbar, alert and hero) against
        // an object that's already been removed from the context, which
        // can crash. Deferring the delete to the next run loop turn gives
        // the dismiss/pop transition a chance to start first.
        dismiss()
        let context = modelContext
        let target = list
        DispatchQueue.main.async {
            context.delete(target)
        }
    }
}
