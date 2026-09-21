import Foundation
import SwiftData

/// Every change the app can make to a list's contents: adding an item,
/// deleting one, reordering, tidying up after a rename, and deleting the list
/// itself.
///
/// These were private methods on `ListDetailView`, which meant the app's
/// actual CRUD — the thing a user spends all their time doing — was the one
/// part of the codebase no unit test could reach. The token, copy, motion and
/// contrast suites all ran green without a single item ever having been
/// added, renamed, reordered or deleted; only the UI tests touched any of it,
/// at ~74 s a run.
///
/// `PickService` already showed the shape that works here: a small struct
/// over a `ModelContext`, doing the SwiftData part, with anything that
/// doesn't need SwiftData written as a pure function beside it.
struct ListEditor {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: Items

    /// Appends an item to `list`. Returns `nil` — changing nothing — for a
    /// name that is empty once trimmed, which is how both "Add" buttons in the
    /// app already behaved.
    @discardableResult
    func addItem(named name: String, to list: PickList) -> PickItem? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let item = PickItem(name: trimmed, sortOrder: Self.nextSortOrder(after: list.items.map(\.sortOrder)))
        list.items.append(item)
        context.insert(item)
        return item
    }

    /// Removes `item` from `list` and closes the gap it leaves, so the
    /// remaining items keep consecutive `sortOrder`s.
    func delete(_ item: PickItem, from list: PickList) {
        list.items.removeAll { $0.id == item.id }
        context.delete(item)
        renumber(list)
    }

    /// Moves `item` `offset` places through `list` — `-1` for up, `+1` for
    /// down. A move that would run off either end does nothing, which is what
    /// keeps the first row's "up" and the last row's "down" harmless even if
    /// their disabled state is ever missed.
    func move(_ item: PickItem, in list: PickList, by offset: Int) {
        var ordered = list.orderedItems
        guard let index = ordered.firstIndex(where: { $0.id == item.id }) else { return }
        let destination = index + offset
        guard ordered.indices.contains(destination) else { return }

        ordered.swapAt(index, destination)
        for (position, orderedItem) in ordered.enumerated() {
            orderedItem.sortOrder = position
        }
    }

    /// Rewrites every `sortOrder` to its position, so the list has no gaps or
    /// ties. Ties matter: `PickList.orderedItems` sorts on `sortOrder`, and
    /// Swift's sort isn't stable, so two items sharing one would be free to
    /// swap places between redraws.
    func renumber(_ list: PickList) {
        for (position, item) in list.orderedItems.enumerated() {
            item.sortOrder = position
        }
    }

    // MARK: Lists

    func delete(_ list: PickList) {
        context.delete(list)
    }

    /// Tidies up whatever edit mode left behind: trims stray whitespace from
    /// the list's name and every item's.
    ///
    /// Unlike the create paths, which simply refuse an empty name, this falls
    /// back to something non-empty — because these are live two-way bindings
    /// straight into the model (`$list.name`, `$item.name`). Rejecting an
    /// empty value on every keystroke would make backspacing a field clear to
    /// retype it impossible: it would snap back to the old text on the last
    /// backspace. So typing stays completely free, including through an empty
    /// in-between state, and this fixes up what's left once editing ends.
    func commitEdits(to list: PickList, fallingBackTo previousName: String) {
        let trimmedTitle = list.name.trimmingCharacters(in: .whitespacesAndNewlines)
        list.name = trimmedTitle.isEmpty ? previousName : trimmedTitle

        for item in list.items {
            let trimmed = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            item.name = trimmed.isEmpty ? Self.untitledItemName : trimmed
        }
    }

    /// What an item left blank is called once editing ends.
    static let untitledItemName = "Untitled"

    // MARK: Pure

    /// The `sortOrder` for something appended after `existing`. Position, not
    /// count: deleting from the middle and appending again must not reuse an
    /// order that is still in use.
    static func nextSortOrder(after existing: [Int]) -> Int {
        (existing.max() ?? -1) + 1
    }
}
