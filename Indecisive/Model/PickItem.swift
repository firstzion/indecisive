import Foundation
import SwiftData

/// A single candidate within a `PickList` (e.g. "Pho Palace" inside "Lunch Places").
@Model
final class PickItem {
    var name: String
    var sortOrder: Int
    var createdAt: Date

    init(name: String, sortOrder: Int = 0, createdAt: Date = .now) {
        self.name = name
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}
