import Foundation
import SwiftData

/// A list of candidates the user can't decide between (e.g. "Lunch Places").
@Model
final class PickList {
    var name: String

    /// Index into the current skin's flavour palette — the Gumball capsule
    /// colour, the Wheel's first wedge colour, etc. See `SkinPalette`.
    var flavorIndex: Int

    /// Manual ordering for the home screen (SwiftData arrays have no
    /// guaranteed order), lowest first.
    var sortOrder: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var items: [PickItem] = []

    @Relationship(deleteRule: .cascade)
    var picks: [Pick] = []

    init(name: String, flavorIndex: Int = 0, sortOrder: Int = 0, createdAt: Date = .now) {
        self.name = name
        self.flavorIndex = flavorIndex
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    /// `items` sorted for stable display and picking — SwiftData's array
    /// order is not guaranteed to match insertion order.
    var orderedItems: [PickItem] {
        items.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// The most recent *accepted* pick for this list — feeds the "Last pick:
    /// Pho Palace, Tuesday" line on the detail screen. `nil` if nothing has
    /// been accepted yet (rejections during re-rolls don't count).
    var lastAcceptedPick: Pick? {
        picks.filter(\.accepted).max { $0.date < $1.date }
    }
}
