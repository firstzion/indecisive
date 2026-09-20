import XCTest
import SwiftData
@testable import IndecisiveKit

/// `PickCounter` replaced a `@Query` that loaded every `Pick` ever recorded
/// in order to count them. The count has to stay exactly as live as that
/// `@Query` was, or the swap is a regression — so these pin both halves:
/// the number is right, and it keeps up when picks are recorded elsewhere.
@MainActor
final class PickCounterTests: XCTestCase {

    /// Polls until `condition` holds. `PickCounter` refreshes on a later
    /// turn of the main actor rather than inside the save notification
    /// (deliberately — see its doc comment), so there is nothing to await
    /// directly.
    private func eventually(
        _ condition: () -> Bool,
        timeout: TimeInterval = 2
    ) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            try? await Task.sleep(for: .milliseconds(10))
        }
        return condition()
    }

    func testItStartsAtZeroWhenNothingHasBeenPicked() throws {
        let container = try TestSupport.makeInMemoryContainer()
        let counter = PickCounter(context: container.mainContext)
        XCTAssertEqual(counter.total, 0)
    }

    func testItStartsFromWhatIsAlreadyInTheStore() throws {
        let container = try TestSupport.makeInMemoryContainer()
        let context = container.mainContext
        let list = PickList(name: "Lunch")
        let item = PickItem(name: "Pho Palace", sortOrder: 0)
        list.items = [item]
        context.insert(list)

        let service = PickService(context: context)
        service.record(item, in: list, accepted: true)
        service.record(item, in: list, accepted: false)
        try context.save()

        // Built *after* the picks — it must read the store, not just count
        // what it has seen happen since.
        let counter = PickCounter(context: context)
        XCTAssertEqual(counter.total, 2)
    }

    func testItKeepsUpWhenAPickIsRecordedAfterwards() async throws {
        // The whole point of the class: a pick recorded on the reveal screen
        // has to reach Home's footer. The version before this one was an
        // untracked `fetchCount` that never noticed.
        let container = try TestSupport.makeInMemoryContainer()
        let context = container.mainContext
        let list = PickList(name: "Lunch")
        let item = PickItem(name: "Pho Palace", sortOrder: 0)
        list.items = [item]
        context.insert(list)
        try context.save()

        let counter = PickCounter(context: context)
        XCTAssertEqual(counter.total, 0)

        let service = PickService(context: context)
        service.record(item, in: list, accepted: false)
        try context.save()

        let updated = await eventually { counter.total == 1 }
        XCTAssertTrue(updated, "the counter should have caught up with the recorded pick — saw \(counter.total)")
    }

    func testItCountsRejectedRerollsAndAcceptedPicksAlikeAcrossEveryList() async throws {
        let container = try TestSupport.makeInMemoryContainer()
        let context = container.mainContext
        let lunch = PickList(name: "Lunch")
        let movies = PickList(name: "Movie Night")
        let lunchItem = PickItem(name: "Pho Palace", sortOrder: 0)
        let movieItem = PickItem(name: "Some Movie", sortOrder: 0)
        lunch.items = [lunchItem]
        movies.items = [movieItem]
        context.insert(lunch)
        context.insert(movies)
        try context.save()

        let counter = PickCounter(context: context)
        let service = PickService(context: context)
        service.record(lunchItem, in: lunch, accepted: true)
        service.record(movieItem, in: movies, accepted: false)
        service.record(lunchItem, in: lunch, accepted: false)
        try context.save()

        let updated = await eventually { counter.total == 3 }
        XCTAssertTrue(updated, "every pick counts, accepted or not, whichever list it came from — saw \(counter.total)")
    }

    func testRefreshingByHandAgreesWithFetchCount() throws {
        let container = try TestSupport.makeInMemoryContainer()
        let context = container.mainContext
        let list = PickList(name: "Lunch")
        let item = PickItem(name: "Pho Palace", sortOrder: 0)
        list.items = [item]
        context.insert(list)

        let counter = PickCounter(context: context)
        let service = PickService(context: context)
        for _ in 0..<5 { service.record(item, in: list, accepted: false) }
        try context.save()

        counter.refresh()
        XCTAssertEqual(counter.total, service.totalPickCount)
        XCTAssertEqual(counter.total, 5)
    }
}
