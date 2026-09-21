import XCTest
import SwiftData
@testable import IndecisiveKit

final class SeedDataTests: XCTestCase {

    func testSeedsOnlyLunchPlacesOnEmptyStore() throws {
        let context = try TestSupport.makeInMemoryContext()
        SeedData.seedIfNeeded(context: context)

        let lists = try context.fetch(FetchDescriptor<PickList>())
        XCTAssertEqual(lists.count, 1)
        XCTAssertEqual(lists.map(\.name), ["Lunch Places"])
    }

    func testLunchPlacesGetsTheSixMockupItemsInOrder() throws {
        let context = try TestSupport.makeInMemoryContext()
        SeedData.seedIfNeeded(context: context)

        let lists = try context.fetch(FetchDescriptor<PickList>())
        let lunch = try XCTUnwrap(lists.first { $0.name == "Lunch Places" })

        XCTAssertEqual(
            lunch.orderedItems.map(\.name),
            [
                "Taco Truck on 9th",
                "Sushi Counter",
                "Pho Palace",
                "Green Bowl Salads",
                "Big Jim's Burgers",
                "The Dumpling Cart",
            ])
    }

    func testSeedingTwiceDoesNotDuplicate() throws {
        let context = try TestSupport.makeInMemoryContext()
        SeedData.seedIfNeeded(context: context)
        SeedData.seedIfNeeded(context: context)  // simulates a second app launch

        let lists = try context.fetch(FetchDescriptor<PickList>())
        XCTAssertEqual(lists.count, 1, "seeding must be a no-op once data already exists")
    }

    func testSeedingIsSkippedIfAnyListAlreadyExists() throws {
        let context = try TestSupport.makeInMemoryContext()
        context.insert(PickList(name: "User's own list"))
        try context.save()

        SeedData.seedIfNeeded(context: context)

        let lists = try context.fetch(FetchDescriptor<PickList>())
        XCTAssertEqual(lists.count, 1, "must not seed on top of a store that already has user data")
    }
}
