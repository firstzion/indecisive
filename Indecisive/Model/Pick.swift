import Foundation
import SwiftData

/// A record of one reveal — either accepted ("sold, let's go") or rejected
/// ("nope, roll again"). Stores a snapshot of the item's name rather than a
/// reference to `PickItem`, so history survives the item itself being renamed
/// or deleted later.
@Model
final class Pick {
    var itemName: String
    var date: Date
    var accepted: Bool

    init(itemName: String, date: Date = .now, accepted: Bool) {
        self.itemName = itemName
        self.date = date
        self.accepted = accepted
    }
}
