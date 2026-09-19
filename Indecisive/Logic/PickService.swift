import Foundation
import SwiftData

/// Chooses "the pick" from a list, records reveal history, and reports the
/// running total of picks made across every list.
///
/// The random-selection algorithm (`Self.choose`) is a pure, generic function
/// with no SwiftData dependency, so it's unit tested directly with plain
/// structs and an injected `RandomNumberGenerator`. `PickService` itself
/// wraps that with the SwiftData side: reading `PickList.orderedItems`,
/// writing `Pick` history, and the global counter.
struct PickService {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    /// Picks uniformly at random from `list`'s items, excluding
    /// `excludedIDs` (the winners already rejected during this reveal
    /// session). Returns `nil` only if the list has no items at all.
    func pick(
        from list: PickList,
        excluding excludedIDs: Set<PersistentIdentifier> = []
    ) -> PickItem? {
        var rng = SystemRandomNumberGenerator()
        return Self.choose(from: list.orderedItems, excluding: excludedIDs, using: &rng)
    }

    /// Records a pick in `list`'s history. `accepted` distinguishes a final
    /// "sold, let's go" from a rejected "nope, roll again" — only accepted
    /// picks count as the list's `lastAcceptedPick`, but every pick (accepted
    /// or not) counts toward `totalPickCount`, so a run of re-rolls still
    /// makes the 8-Ball's "the ball has spoken" counter climb.
    @discardableResult
    func record(_ item: PickItem, in list: PickList, accepted: Bool) -> Pick {
        let pick = Pick(itemName: item.name, accepted: accepted)
        list.picks.append(pick)
        context.insert(pick)
        return pick
    }

    /// Total number of picks (accepted or rejected) ever made, across every
    /// list. Feeds the Midnight 8-Ball skin's home-screen footer ("THE BALL
    /// HAS SPOKEN {n} TIMES").
    var totalPickCount: Int {
        (try? context.fetchCount(FetchDescriptor<Pick>())) ?? 0
    }

    /// Pure selection logic, decoupled from SwiftData for testability.
    ///
    /// Picks uniformly at random from `items`, excluding anything in
    /// `excludedIDs`. If every item is excluded (the player has rejected
    /// every candidate in this session), the exclusion set is treated as
    /// exhausted and every item becomes eligible again — a re-roll can never
    /// get permanently stuck once every item's been seen. Returns `nil` only
    /// when `items` is empty to begin with.
    static func choose<Item: Identifiable, RNG: RandomNumberGenerator>(
        from items: [Item],
        excluding excludedIDs: Set<Item.ID>,
        using rng: inout RNG
    ) -> Item? where Item.ID: Hashable {
        guard !items.isEmpty else { return nil }
        var pool = items.filter { !excludedIDs.contains($0.id) }
        if pool.isEmpty { pool = items }
        return pool.randomElement(using: &rng)
    }
}
