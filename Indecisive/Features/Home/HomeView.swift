import SwiftUI
import SwiftData

/// The app's home screen: the list of lists, "+" to create one, and the
/// skin's footer line (the 8-Ball's running "the ball has spoken" counter).
struct HomeView: View {
    @Environment(\.skin) private var skin
    @Environment(\.modelContext) private var modelContext
    @Environment(\.didFailToLoadPersistedStore) private var didFailToLoadPersistedStore
    @Query(sort: \PickList.sortOrder) private var lists: [PickList]
    /// Backs `totalPickCount`. Created on appear rather than held as a
    /// `@Query`, because the footer needs a *number* and a `@Query` would
    /// hand it every `Pick` ever recorded to count them — see `PickCounter`,
    /// which documents why this line has now been written three ways.
    @State private var pickCounter: PickCounter?
    @State private var showingNewList = false
    @State private var showingSkinPicker = false
    @State private var showingStoreLoadFailureAlert = false
    @State private var hasShownStoreLoadFailureAlert = false
    /// The list a trailing swipe wants to delete, pending confirmation —
    /// `nil` means no confirmation is up. An identity, not a `Bool`, so the
    /// alert (which fires after the row itself may already be gone from
    /// `lists`) still has the right name/list to act on.
    @State private var listPendingDeletion: PickList?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    header

                    // Stays for the whole session, unlike the alert below,
                    // which fires once — see `StoreFailureBanner`.
                    if didFailToLoadPersistedStore {
                        StoreFailureBanner(skin: skin)
                    }

                    if lists.isEmpty {
                        emptyStatePlaceholder
                    } else {
                        ForEach(lists) { list in
                            SwipeToDeleteRow(skin: skin, onDeleteRequested: { listPendingDeletion = list }) {
                                NavigationLink(value: list) {
                                    ListCard(skin: skin, list: list)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Button {
                        showingNewList = true
                    } label: {
                        DashedAddRow(skin: skin, label: skin.copy.newListRow)
                    }
                    .buttonStyle(.plain)

                    footer
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(skin.palette.background)
            .navigationDestination(for: PickList.self) { list in
                ListDetailView(list: list)
            }
            .sheet(isPresented: $showingNewList) {
                NewListSheet(skin: skin, onCreate: createList)
            }
            .sheet(isPresented: $showingSkinPicker) {
                SkinPickerSheet()
            }
        }
        .tint(skin.palette.accent)
        .preferredColorScheme(skin.palette.colorScheme)
        .onAppear {
            // Built here, not at init: it needs the `modelContext` from the
            // environment. Made once and kept — it watches the store from
            // then on, including while Detail is covering this screen.
            if pickCounter == nil {
                pickCounter = PickCounter(context: modelContext)
            }

            // Guarded by `hasShownStoreLoadFailureAlert` so navigating back
            // to Home from Detail doesn't re-show this every time — it
            // should fire at most once per launch.
            guard didFailToLoadPersistedStore, !hasShownStoreLoadFailureAlert else { return }
            hasShownStoreLoadFailureAlert = true
            showingStoreLoadFailureAlert = true
        }
        .alert("Couldn't load your saved lists", isPresented: $showingStoreLoadFailureAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                "Something went wrong opening your saved data, so Rand-o-matic started fresh this launch. Your previous lists may be lost.")
        }
        .alert(
            "Delete list?",
            isPresented: Binding(
                get: { listPendingDeletion != nil },
                set: { isPresented in if !isPresented { listPendingDeletion = nil } }
            ),
            presenting: listPendingDeletion
        ) { list in
            Button("Delete", role: .destructive) { deleteList(list) }
            Button("Cancel", role: .cancel) {}
        } message: { list in
            Text("This removes “\(list.name)” and everything in it. This can't be undone.")
        }
    }

    private var header: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Rand-o-matic")
                    .font(skin.type.display(36, weight: .extrabold))
                    .foregroundStyle(skin.palette.titleText)
                    // Sized for "Wizard of Odds"; "Rand-o-matic" is a
                    // different shape and wraps mid-hyphen at a fixed 36pt
                    // in some skins' display faces. Shrink-to-fit instead
                    // of hardcoding a smaller size, so the title stays
                    // correct (and still as large as possible) whatever
                    // name ends up here next.
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    // Playful extra entry point to the skin picker,
                    // alongside the palette button below (PLAN.md §5).
                    .onLongPressGesture { showingSkinPicker = true }
                Text(skin.copy.homeSubtitle(lists.count))
                    .font(skin.type.body(14, weight: .semibold))
                    .foregroundStyle(skin.palette.secondaryText)
            }
            Spacer()
            SkinIconButton(skin: skin, glyph: "🎨", accessibilityLabel: "Skins", variant: .secondary, size: 36) {
                showingSkinPicker = true
            }
            SkinIconButton(skin: skin, glyph: "+", accessibilityLabel: "New list", variant: .primary) {
                showingNewList = true
            }
        }
        .padding(.bottom, 4)
    }

    /// Shown instead of the (empty) list-row area when there are no lists
    /// yet — a fresh install's brief window before `SeedData` populates it,
    /// or after deleting every list. Mirrors `ListDetailView`'s
    /// `emptyItemsPlaceholder` styling for visual consistency between the
    /// two "nothing here yet" states in the app.
    private var emptyStatePlaceholder: some View {
        VStack(spacing: 6) {
            Text(skin.copy.homeEmptyStateTitle)
                .font(skin.type.display(18, weight: .bold, relativeTo: .body))
                .foregroundStyle(skin.palette.primaryText)
                .multilineTextAlignment(.center)
            Text(skin.copy.homeEmptyStateMessage)
                .font(skin.type.body(13, weight: .semibold))
                .foregroundStyle(skin.palette.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .indCard(skin)
    }

    private var footer: some View {
        Text(skin.copy.homeFooter(totalPickCount))
            .font(skin.type.body(13, weight: .semibold))
            .foregroundStyle(skin.palette.tertiaryText)
            .multilineTextAlignment(.center)
    }

    private var totalPickCount: Int {
        pickCounter?.total ?? 0
    }

    private func createList(named name: String, flavorIndex: Int) {
        let nextOrder = (lists.map(\.sortOrder).max() ?? -1) + 1
        let list = PickList(name: name, flavorIndex: flavorIndex, sortOrder: nextOrder)
        modelContext.insert(list)
    }

    private func deleteList(_ list: PickList) {
        modelContext.delete(list)
    }
}
