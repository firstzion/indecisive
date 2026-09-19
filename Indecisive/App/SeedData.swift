import Foundation
import SwiftData

/// Seeds the sample "Lunch Places" list shown in the original design
/// mockups (Taco Truck on 9th, Sushi Counter, Pho Palace, Green Bowl
/// Salads, Big Jim's Burgers, The Dumpling Cart) so the app is never empty
/// on first launch. A no-op if any list already exists, so it's safe to
/// call unconditionally at every launch.
enum SeedData {
    static func seedIfNeeded(context: ModelContext) {
        let existingCount = (try? context.fetchCount(FetchDescriptor<PickList>())) ?? 0
        guard existingCount == 0 else { return }

        let lunch = PickList(name: "Lunch Places", flavorIndex: 0, sortOrder: 0)
        lunch.items = [
            PickItem(name: "Taco Truck on 9th", sortOrder: 0),
            PickItem(name: "Sushi Counter", sortOrder: 1),
            PickItem(name: "Pho Palace", sortOrder: 2),
            PickItem(name: "Green Bowl Salads", sortOrder: 3),
            PickItem(name: "Big Jim's Burgers", sortOrder: 4),
            PickItem(name: "The Dumpling Cart", sortOrder: 5),
        ]
        context.insert(lunch)

        try? context.save()
    }
}
